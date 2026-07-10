(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.id))
(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Highlight (require :playtime.highlight))
(local {: api} vim)
(local M {})
(local m {})

;; TODO: push validation and fill of border-style into config getter instead
;; then just build these inline in open.
(fn m.generate-unpositioned-window-configs [{: width : height} border-style]
  "Generate nvim_open_win config values for minimise and maximised views.

  Does not include positioning (besides row/col = 1) as this is set dynamically
  to match user config & neovim window size."
  (let [border-style (case (or border-style vim.o.winborder)
                       (where (or nil "")) :shadow
                       border border)
        max {:relative :editor
             :width width :height height
             :row 1 :col 1
             :style :minimal
             :border border-style}
        min {:relative :editor
             :width 18 :height 1
             :row 1 :col 1
             :style :minimal
             :border :none}]
    {: max : min}))

(fn m.position->components [{: buf : ns : win : extmark-tags &as view} row col]
  "Resolve given row & col into a list of components at that position, sorted
  by descending z index."
  (let [all-extmarks (vim.api.nvim_buf_get_extmarks buf ns [row 0] [row col] {:details true})
        ;; nvim_buf_get_extmarks only returns extmarks by their "anchor/start col",
        ;; So we get *all* extmarks between the start of the row up to the given column,
        ;; then check if they overlap our given column.
        between-extmarks (faccumulate [between [] i (length all-extmarks) 1 -1]
                           (let [[id _row extmark-col-start details] (. all-extmarks i)
                                 {:end_col extmark-col-end :priority z} details
                                 is-between? (and (<= extmark-col-start col) (< col extmark-col-end))]
                             (table.insert between (if is-between? {: id : z}))))
        sorted-extmarks (table.sort between-extmarks (fn [{:z a} {:z b}] (> a b)))]
    (icollect [_ {: id} (ipairs sorted-extmarks)]
      (. extmark-tags id))))

(fn m.create-window-and-buffer [window-config filetype]
  (let [{: width : height} window-config
        buf (api.nvim_create_buf false true)
        win (api.nvim_open_win buf true window-config)]
    ;; We set the lines to 2x the height to allow window overflow and
    ;; scrolling, performance impact seems minimal
    (api.nvim_buf_set_lines buf 0 -1 false (fcollect [_row 1 (* height 2)] (string.rep " " width)))
    (api.nvim_buf_set_option buf :modifiable false)
    (api.nvim_buf_set_option buf :filetype filetype)
    (api.nvim_win_set_option win :wrap false)
    (values win buf)))

(fn m.make-raw-event-adapter-dispatch [dispatch]
  (fn raw-input [lhs data]
    (let [ns :input
          [name button action] (case lhs
                                 :<LeftMouse> [:click :left :press]
                                 :<LeftRelease> [:click :left :release]
                                 :<LeftDrag> [:drag :left :raw]
                                 :<RightMouse> [:click :right :press]
                                 :<RightRelease> [:click :right :release]
                                 :<RightDrag> [:drag :right :raw]
                                 unknown [:window :input unknown])
          data {: action : button
                :row data.row :col data.col
                :target (. data.components 1)
                :targets data.components}]
      {: ns : name : data}))

  (fn [ns name data]
    (let [{: ns : name : data } (case ns
                                  :window {: ns : name : data}
                                  :input (raw-input name data))]
      (dispatch ns name data))))

(λ M.new [{: filetype : size : position :style ?style : dispatch-event}]
  (let [filetype (.. "playtime-" filetype)
        id (Id.new)
        default-window-configs (m.generate-unpositioned-window-configs size ?style)
        ns (api.nvim_create_namespace (string.format "playtime-%s-%s-ns" filetype id))
        window-data {: id : filetype : ns
                     :open? false :minimised? false
                     :position {:when-maximised position.when-maximised
                                :when-minimised position.when-minimised}
                     : size  :style ?style
                     :config default-window-configs
                     :dispatch-event (m.make-raw-event-adapter-dispatch dispatch-event)}
        instance (setmetatable window-data {:__index M})]
    instance))

(λ M.open [self]
  (assert (not self.open?) (Error "Window #{id} already open!" self))
  (let [(win buf) (m.create-window-and-buffer self.config.max self.filetype)]
    (table.merge self {:open? true : win : buf})
    (self:update-window-size)
    (self:update-window-position)
    (self:update-highlights)
    (self:attach-autocmds)
    ;; Probably never not wanting to bind these mouse events, can always not
    ;; write handlers for them.
    (self:bind-mouse [:<LeftMouse> :<LeftDrag> :<LeftRelease>
                      :<RightMouse> :<RightDrag> :<RightRelease>])
    ;; TODO: possible this will be wrong if we open an app from an app
    ;; perhaps better to cache globally on first require, then compare, if
    ;; different to cache but not "a:PlaytimeHiddenCursor", then update cache.
    (set vim.o.guicursor "a:PlaytimeHiddenCursor")
    self))

;; List all mouse events names so we can bind them to #nil if not specifically
;; wanted as well as filter them out from buffer map lists when unbinding.
(local *mouse-binding-names*
  (let [bindings [:<MouseMove>]]
    (each [_ side (ipairs [:Left :Right])]
      (each [_ sub (ipairs [:Mouse :Drag :Release])]
        (each [_ count (ipairs ["" :2- :3- :4-])]
          (table.insert bindings (.. :< count side sub :>)))))
  bindings))

(λ m.unbind-all-mouse [window]
  ;; While we always bind all mouse events, some just being #nil
  ;; we may call this function with zero binds present, so
  ;; we do actually have to be selective in calling the api.
  (let [bindings (api.nvim_buf_get_keymap window.buf :n)
        by-lhs (collect [_ {: lhs &as binding} (ipairs bindings)]
                 (values lhs binding))
        bound (icollect [_ binding-name (ipairs *mouse-binding-names*)]
                (. by-lhs binding-name))]
    (each [_ {: mode : lhs} (ipairs bound)]
      (api.nvim_buf_del_keymap window.buf mode lhs))))

(λ M.bind-mouse [window buttons]
  (assert window.open? "cannot bind mouse before opening window")
  (m.unbind-all-mouse window)
  (let [{: win : buf : dispatch-event} window
        ;; We always bind all mouse events to prevent bad interaction then
        ;; specifically bind desired events to the dispatchter.
        ;; TODO: You can enable mousemove events
        ;; TODO: you can disable mouse in some modes
        ; (api.nvim_win_set_option win :mouse :n)
        ; _ (api.nvim_win_set_option win :mousemoveevent true)
        ;; TODO: you can disable mouse scrolling
        ;; _ (api.nvim_win_set_option win :mousescroll "ver:0,hor:0")
        mouse-bindings (collect [_ b (pairs *mouse-binding-names*)]
                         (values b #nil))
        _ (each [_ button (ipairs buttons)]
            (tset mouse-bindings button #(dispatch-event $...)))
        ;; TODO: if given :<MouseMove> enable mousemoveevent
        ;; we always bind MouseMove anyway because its just a noop if not enabled.
        bind-mouse-lhs (fn [lhs callback desc]
                         (let [cb (vim.schedule_wrap
                                    #(case (vim.fn.getmousepos)
                                       (where {:winid (= win) : line : column})
                                       (let [row (- line 1)
                                             col (- column 1)
                                             components (m.position->components window row col)]
                                         ;; Mouse events over the window border 0,0 line,column values
                                         ;; so -1,-1 row,col values. These are invalid for interaction
                                         ;; and we'll just ignore them.
                                         (case (values row col)
                                           (-1 -1) nil
                                           _ (callback :input lhs {: row : col : components})))
                                       ;; Click was not in our window, we *must* re-dispatch
                                       _ (vim.cmd.exec (string.format "\"normal! \\%s\"" lhs))))]
                           (api.nvim_buf_set_keymap buf :n lhs "" {:callback cb :desc desc})))]
    (each [button callback (pairs mouse-bindings)]
      (bind-mouse-lhs button callback (string.format "%s-%s" window.filetype button))))
  window)

; (λ M.unbind-keys [window])
; (λ M.unbind-all [window]
;   (let [bindings (api.nvim_buf_get_keymap window.buf :n)]
;     (each [_ {: mode : lhs} (ipairs bindings)]
;       (api.nvim_buf_del_keymap window.buf mode lhs))))
; (λ M.rebind-keys [window keys]
;   ;; Unbind non-mouse binds
;   ;; rebind given keys
;   window)


(λ M.minimise [window]
  (set window.minimised? true)
  (window:update-window-size)
  (window:update-window-position))

(λ M.maximise [window]
  (set window.minimised? false)
  (window:update-window-size)
  (window:update-window-position))

(λ M.update-highlights [window]
  (Highlight.define-highlights)
  (tset (. vim :wo window.win) :winhighlight "NormalFloat:PlaytimeBackground")
  window)

(λ M.attach-autocmds [window]
  (let [{: filetype : id : win : buf : dispatch-event} window
        user-guicursor-value vim.o.guicursor
        augroup (api.nvim_create_augroup (.. :playtime- filetype "-" id "-augroup") {:clear true})]
    (api.nvim_create_autocmd :WinClosed
                             {:group augroup
                              :callback (fn [{:match winid}]
                                          (when (= winid (tostring win))
                                            (dispatch-event :window :closed {: window})
                                            (api.nvim_del_augroup_by_id augroup)
                                            true))})
    (api.nvim_create_autocmd :VimResized
                             {:group augroup
                              :callback (fn []
                                          (window:update-window-position)
                                          false)})
    (api.nvim_create_autocmd :ColorScheme
                             {:group augroup
                              :callback (fn [] (window:update-highlights) false)})
    (api.nvim_create_autocmd :BufLeave
                             {:group augroup
                              :buffer buf
                              :callback (fn []
                                          (set window.focused? false)
                                          (set vim.o.guicursor user-guicursor-value)
                                          (dispatch-event :window :unfocused {: window})
                                          false)})
    (api.nvim_create_autocmd :BufEnter
                             {:group augroup
                              :buffer buf
                              :callback (fn []
                                          (set window.focused? true)
                                          (set vim.o.guicursor "a:PlaytimeHiddenCursor")
                                          (dispatch-event :window :focused {: window})
                                          false)})))



(fn M.update-window-position [window]
  "Update the current windows position according to the current vim layout and
  minimisation state."
  (let [{: min : max} window.config
        {: row : col} (case window.minimised?
                        true (case window.position.when-minimised
                               :ne {:row 0 :col (- vim.o.columns min.width)}
                               :nw {:row 0 :col 0}
                               :sw {:row (- vim.o.lines (+ 2 vim.o.cmdheight))
                                    :col 0}
                               :se {:row (- vim.o.lines (+ 2 vim.o.cmdheight))
                                    :col (- vim.o.columns min.width)}
                               {: row : col} {: row : col}
                               (where f (type.function? f))
                               (case (f)
                                 {: row : col} {: row : col}
                                 _ (error "minimise-position function returned invalid value, must be {:row r :col c}"))
                               ?v (error (<s> "invalid minimise-position: #{?v}")))
                        false (case window.position.when-maximised
                                :center {:row 1 :col (- (/ vim.o.columns 2) (/ max.width 2))}
                                :ne {:row 1 :col (- vim.o.columns max.width)}
                                :nw {:row 1 :col 1}
                                {: row : col} {: row : col}
                                (where f (type.function? f))
                                (case (f)
                                  {: row : col} {: row : col}
                                  _ (error "maximise-position function returned invalid value, must be {:row r :col c}"))
                                ?v (error (<s> "invalid maximise-position: #{?v}"))))
        config (case window.minimised?
                 true (table.merge min {: row : col})
                 false (table.merge max {: row : col}))]
    (api.nvim_win_set_config window.win config)
    window))

(fn M.update-window-size [window]
  "Update the window width and height to match its current minimisation state"
  (let [{: buf : win} window
        {: min : max} window.config
        ({: width : height} fill) (case window.minimised?
                                    true (values
                                           {:width window.logo-component.size.width :height 1}
                                           [(string.rep " " window.logo-component.size.width)])
                                    false (values
                                            {:width max.width :height (math.min max.height (- vim.o.lines 4))}
                                            (fcollect [_row 1 (* max.height 2)] (string.rep " " max.width))))
        config (case window.minimised?
                 true (table.merge min {: width : height})
                 false (table.merge max {: width : height}))]
    (api.nvim_buf_set_option buf :modifiable true)
    (api.nvim_buf_set_lines buf 0 -1 false fill)
    (api.nvim_buf_set_option buf :modifiable false)
    (api.nvim_win_set_config win config)
    window))

(fn M.render [view component-trees]
  ;;
  ;; We render elements as extmarks, this gives us the benefits of
  ;;
  ;; - Not having to calculate byte-offsets for multi-byte characters when
  ;;   calling nvim_buf_add_highlight.
  ;; - Simpler definition of graphics, given as [[text highlight]] lines,
  ;;   instead of separate char lookups with potential "visible width" and
  ;;   "byte width" components for each row/col multi-byte char.
  ;; - Simpler hit-detection by having an empty buffer, converting
  ;;   the mouse click/cursor positions into row/col pairs is uncomplicated
  ;;   because there are never any multi-byte characters to accommodate.
  ;; - Minimally: Its harder to damage the UI by editing it
  ;;
  ;; It has the downsides that you cant copy the UI state out, or save the
  ;; buffer in some meaningful way ("screenshotting", etc)
  ;;
  (let [component-trees (if view.minimised? [view.logo-component] component-trees)
        {:size {:width frame-width :height frame-height} : ns : buf : win} view
        {: nvim_buf_set_extmark} vim.api
        extmark-tags []
        overflow-height (* frame-height 2)]

    (fn draw [component]
      (when component.visible?
        (case (component:content-to-renderable)
          render-lines (let [{:size {: width : height} :position {: col : row : z}} component]
                         (for [line 1 height]
                           ;; TODO: extend the buffer to always fit everything?
                           ;; We cant put extmarks on rows outside the buffer, so clip
                           ;; any lines that go too far.
                           ;; Note: We dont set the end-col past the frame, but we *do
                           ;; not* actually clip components that run past the buffer edge.
                           ;; Neovim will push these back into view which we will live
                           ;; with for now.

                           ;; Dont render things that are outside of the view, this may occur
                           ;; during animations.
                           ;; Note our content is 1-indexed but line/row and column are 0 indexed
                           ;; both in neovims api, and in our position system. So we adjust the
                           ;; -1 the line, but column can stay as given.
                           (let [render-row (+ row (- line 1))]
                             ;; TODO: there is an asymmetry here, dragging to far right will pin
                             ;; a card to the far edge, too far left and it disappears.
                             ;; This is because the start-col of the component is less than 0
                             ;; so we never draw any of it.
                             ;; We could clamp the col val to 0 frame-width, or
                             ;; snip some columns from the render content.
                             (when (and (<= 0 render-row (- overflow-height 1))
                                        (<= 0 col frame-width))
                               (case (. render-lines line)
                                  {: extmark-id : line}
                                  (do
                                    (local test (nvim_buf_set_extmark buf ns render-row col
                                                          {:id extmark-id
                                                           :virt_text line
                                                           :virt_text_pos :overlay
                                                           :priority z
                                                           :end_col (math.clamp (+ col width)
                                                                                0 (- frame-width 1))}))
                                    ;; Components are interactable if they have a
                                    ;; tag -- used by responders to identify, or
                                    ;; some handler inside `on` -- used directly
                                    ;; in dispatch.
                                    ;; TODO: NG, `next` is probably fast enough
                                    ;; and we do want to send events to click,
                                    ;; drag, focus (?) and maybe any others that
                                    ;; appear, so checking for *any* on value
                                    ;; seems ok.
                                    (if (or component.tag (next component.on))
                                      (tset extmark-tags extmark-id component)))
                                  ;; TODO: hard error, logger error or warning?
                                  nil (error (<s> "Component #{id}/#{tag} of height #{height} did not have content for line #{line}"
                                                        {:id component.id :tag (vim.inspect component.tag)
                                                         :height component.size.height}))))))))
        (each [_ child (ipairs (or component.children []))]
          (draw child))))

    (api.nvim_buf_clear_namespace buf ns 0 -1)
    (each [_ root (ipairs component-trees)] (draw root))
    (set view.extmark-tags extmark-tags)))

M

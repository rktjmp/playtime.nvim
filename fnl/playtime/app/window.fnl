(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.common.id))
(local Logger (require :playtime.logger))
(local Error (require :playtime.error))
(local Highlight (require :playtime.highlight))
(local Component (require :playtime.component))
(local {: api} vim)
(local M {})

(fn position->component-tags [{: buf : ns : win : extmark-tags &as view} row col]
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

(fn mouse-defaults []
  (let [bindings {}]
    (each [_ side (ipairs [:Left :Right])]
      (each [_ sub (ipairs [:Mouse :Drag :Release])]
        (table.set bindings (.. :< side sub :>) #nil)))
    (each [_ count (ipairs [:2- :3- :4-])]
      (table.set bindings (.. :< count :LeftMouse :>) #nil))
    (each [_ count (ipairs [:2- :3- :4-])]
      (table.set bindings (.. :< count :RightMouse :>) #nil))
    bindings))

(λ bind-mouse [{: win : buf &as view} lhs desc callback]
  (let [cb (vim.schedule_wrap
             #(case (vim.fn.getmousepos)
                (where {:winid (= win) : line : column})
                (let [row (- line 1)
                      col (- column 1)
                      tags (position->component-tags view (- line 1) (- column 1))]
                  (callback lhs tags {: row : col}))
                ;; Click was not in our window, we *must* re-dispatch
                _ (vim.cmd.exec (string.format "\"normal! \\%s\"" lhs))))]
    (api.nvim_buf_set_keymap buf :n lhs "" {:callback cb :desc desc})))

(fn bind-key [{: buf} lhs desc callback]
  (api.nvim_buf_set_keymap buf :n lhs "" {:callback callback :desc desc}))

(λ M.open [filetype dispatch {: width : height : window-position : minimise-position}]
  (λ mutate-configs-to-geometry! [max-config min-config]
    (let [max-pos (case-try
                    (case window-position
                      :center {:row 1 :col (- (/ vim.o.columns 2) (/ width 2))}
                      :ne {:row 1 :col (- vim.o.columns width)}
                      :nw {:row 1 :col 1}
                      {: row : col} {: row : col}
                      (where f (type.function? f)) (f)) {: row : col}
                    {: row : col}
                    (catch
                      ?pos (error (<s> "Unsupported window position: #{?pos}"))))
          min-pos (case-try
                    (case minimise-position
                      :ne {:row 0 :col (- vim.o.columns 18)}
                      :nw {:row 0 :col 0}
                      :sw {:row (- vim.o.lines (+ 2 vim.o.cmdheight))
                           :col 0}
                      :se {:row (- vim.o.lines (+ 2 vim.o.cmdheight))
                           :col (- vim.o.columns 18)}
                      {: row : col} {: row : col}
                      (where f (type.function? f)) (f)) {: row : col}
                    {: row : col}
                    (catch
                      ?pos (error (<s> "Unsupported minimise position: #{?pos}"))))]
      (set max-config.height (math.min height (- vim.o.lines 4)))
      (set max-config.row max-pos.row)
      (set max-config.col max-pos.col)
      (set min-config.row min-pos.row)
      (set min-config.col min-pos.col)))

  (let [win-maxi-config {:relative :editor
                         :width width
                         :height height
                         :style :minimal
                         :border :shadow}
        win-mini-config {:relative :editor
                         :width 18
                         :height 1
                         :style :minimal
                         :border :none}
        _ (mutate-configs-to-geometry! win-maxi-config win-mini-config)
        buf (api.nvim_create_buf false true)
        win (api.nvim_open_win buf true win-maxi-config)
        internal-name (string.format "%s-%s" filetype (Id.new))
        ns (api.nvim_create_namespace (.. internal-name "-ns"))
        augroup (api.nvim_create_augroup (.. internal-name "-augroup") {:clear true})
        user-guicursor-value vim.o.guicursor
        logo-component (-> (Component.build)
                           (Component.set-position {:row 0 :col 1 :z 500})
                           (Component.set-size {:width (string.col-width "🅿 🅻 🅰 🆈 🆃i🅸 🅼 🅴 ") :height 1})
                           (Component.set-content [[["🄿 🄻 🄰 🅈 🅃 🄸 🄼 🄴 " "@playtime.ui.menu"]]]))
        view {: width : height
              : buf : win : ns
              : augroup
              : logo-component}]
    ;; We set the lines to 2x the height to allow window overflow and
    ;; scrolling, performance impact seems minimal
    (api.nvim_buf_set_lines buf 0 -1 false (fcollect [row 1 (* height 2)] (string.rep " " width)))
    (api.nvim_buf_set_option buf :modifiable false)
    (api.nvim_buf_set_option buf :filetype (.. :playtime. filetype))
    (api.nvim_win_set_option win :wrap false)
    (Highlight.define-highlights)
    (tset (. vim :wo win) :winhighlight "NormalFloat:PlaytimeBackground")
    (set vim.o.guicursor "a:PlaytimeHiddenCursor")

    (assert (?. dispatch :window :via) "Must provide dispatch.window.via function")
    (api.nvim_create_autocmd :WinClosed
                             {:group augroup
                              :callback (fn [{:match winid}]
                                          (when (= winid (tostring win))
                                            (dispatch.window.via :quit)
                                            (api.nvim_del_augroup_by_id augroup)
                                            true))})
    (api.nvim_create_autocmd :VimResized
                             {:group augroup
                              :callback (fn []
                                          (mutate-configs-to-geometry! win-maxi-config win-mini-config)
                                          (if view.minimised?
                                            (api.nvim_win_set_config win win-mini-config)
                                            (api.nvim_win_set_config win win-maxi-config))
                                          false)})
    (api.nvim_create_autocmd :ColorScheme
                             {:group augroup
                              :callback (fn []
                                          (Highlight.define-highlights)
                                          (tset (. vim :wo win) :winhighlight "NormalFloat:PlaytimeBackground")
                                          false)})

    (api.nvim_create_autocmd :BufLeave
                             {:group augroup
                              :buffer buf
                              :callback (fn []
                                          (set vim.o.guicursor user-guicursor-value)
                                          (set view.minimised? true)
                                          (api.nvim_win_set_cursor win [1 0])
                                          (api.nvim_win_set_config win win-mini-config)
                                          (view:render [[logo-component]])
                                          false)})
    (api.nvim_create_autocmd :BufEnter
                             {:group augroup
                              :buffer buf
                              :callback (fn []
                                          (set vim.o.guicursor "a:PlaytimeHiddenCursor")
                                          (set view.minimised? false)
                                          (api.nvim_win_set_cursor win [1 0])
                                          (api.nvim_win_set_config win win-maxi-config)
                                          ;; Trigger app render
                                          (dispatch.window.via :noop)
                                          false)})

    (case dispatch.mouse
      {: via : events}
      (let [bindings (table.merge (mouse-defaults) (collect [_ event (ipairs events)]
                                                     (values event via)))]
        (each [key cb (pairs bindings)]
          (bind-mouse view key (<s> "playtime #{filetype} dispatch") cb)))
      _ (each [key cb (pairs mouse-defaults)]
          (bind-mouse view key (<s> "playtime #{filetype} dispatch") cb)))
    (setmetatable view {:__index M})))

(fn M.render [view component-layers]
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
  (let [component-layers (if view.minimised?
                           [[view.logo-component]]
                           component-layers)
        {:width frame-width :height frame-height : ns : buf : win} view
        {: nvim_buf_set_extmark} vim.api
        extmark-tags []
        overflow-height (* frame-height 2)]
    (fn draw [component]
      (when component.visible?
        (let [{: row : col : width : height :tag ?tag : z} component]
          (for [line 1 height]
            ;; TODO: extend the buffer to always fit everything?
            ;; We cant put extmarks on rows outside the buffer, so clip
            ;; any lines that go too far.
            ;; Note: We dont set the end-col past the frame, but we *do
            ;; not* actually clip components that run past the buffer edge.
            ;; Neovim will push these back into view which we will live
            ;; with for now.
            (if (<= (+ row (- line 1)) (- overflow-height 1))
              (let [{: extmark-id : content} (component:content-at line)]
                (nvim_buf_set_extmark buf ns (+ row line -1) col
                                      {:id extmark-id
                                       :virt_text content
                                       :virt_text_pos :overlay
                                       :priority z
                                       :end_col (math.clamp (+ col width)
                                                            0 (- frame-width 1))})
                ;; not all components will have an interaction tag
                (tset extmark-tags extmark-id ?tag)))))
        (each [_ child (ipairs (or component.children []))]
          (draw child))))

    (api.nvim_buf_clear_namespace buf ns 0 -1)
    (each [_ layer (ipairs component-layers)]
      (each [_ comp (ipairs layer)]
        (case comp
          ;; note: some components wont have a row/col until they are visible
          (where {: row : col &as comp} (<= 0 col frame-width) (<= 0 row (- overflow-height 1)))
          (draw comp))))

    (set view.extmark-tags extmark-tags)))

M

(require-macros :playtime.prelude)
(prelude)

(local Logger (require :playtime.logger))
(local Component (require :playtime.component))

(local M {})

(fn M.new [{: width : spec}]
  ;; [["Game Name" nil
  ;;   [["" nil] ;empty space
  ;;    ["new game" [:app :new-game {:mode :easy}]]]]]

  (fn make-menubar-menu [parent items column]
    (let [menubar-menu-width (accumulate [max 0 _ [s _] (ipairs items)]
                  (math.max max (string.col-width (.. " " s " "))))
          format-text (fn [menu-text]
                        ;; cant use string.format due to utf8 chars
                        (let [text-width (string.col-width menu-text)
                              ;; -1 for leading space
                              right-padding (- menubar-menu-width text-width 1)]
                          (.. " " menu-text (string.rep " " right-padding))))]
      (icollect [i [text menu-action] (ipairs items)]
        (Component.new {:position {:col column :row i :z 1002}
                        :size {:width menubar-menu-width :height 1}
                        :visible? false
                        :content [[[(format-text text) "@playtime.ui.menu"]]]
                        ;; Always have a handler so clicking blank spaces does not
                        ;; trigger a click-away and close the menu.
                        :on {:click (fn [self context event fx]
                                      (case event
                                        {:button :left :action :release}
                                        (when menu-action
                                          (let [[event-ns event-name data] menu-action]
                                            (fx.event.dispatch event-ns event-name data)
                                            (fx.focus.release parent)))))}}))))
  (fn make-menubar-item [[text children] column]
    (let [text (.. " " text " ")
          component (Component.new {:position {:col column :row 0 :z 1001}
                      :size {:width (string.col-width text) :height 1}
                      :content [[[text "@playtime.ui.menu"]]]
                      :open (fn [self effects]
                              (each [_ c (ipairs self.children)]
                                (set c.visible? true))
                              (effects.engine.render))
                      :close (fn [self effects]
                               (each [_ c (ipairs self.children)]
                                 (set c.visible? false))
                               (effects.engine.render))
                      :on {:click (fn [self context event effects]
                                    (effects.focus.capture self)
                                    (self:open effects))
                           :focus (fn [self context event effects]
                                    (case event
                                      {:action :release} (self:close effects)))}})
          children (make-menubar-menu component children column)]
      (set component.children children)
      component))

  ;; first has 0 offset, others are offset by previous, insert 0 at head.
  (let [menubar-item-columns (doto (icollect [_ [name _tag _children] (ipairs spec)]
                                     (+ 3 (length name)))
                               (table.insert 1 0))]
    (Component.new {:position {:row 0 :col 0 :z 1000}
                    :size {: width :height 1}
                    :content [[[(string.rep " " width)
                                "@playtime.ui.menu"]]]
                    :children (icollect [i top-item (ipairs spec)]
                                (make-menubar-item top-item (. menubar-item-columns i)))})))

M

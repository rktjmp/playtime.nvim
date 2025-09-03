(require-macros :playtime.prelude)
(prelude)

(local Id (require :playtime.id))
(local Error (require :playtime.error))

(local M {})

(fn content->extmark-lines [content height]
  (fcollect [i 1 height]
    (let [line (case (. content i)
                 nil [[""]]
                 [nil] [[""]]
                 line line)]
      {:extmark-id (Id.new) :line line})))

(fn memoize-content [component]
  ;; Process component content if it differs from what we saw last time.
  ;; Allows for setting component.content via tset without metatable setter,
  ;; the component largely remains a bag of data, while maintaining
  ;; performance.
  ;;
  ;; Some components have no "content" but may have handlers attached in which
  ;; case we need to generate some blank content for the extmarks to be
  ;; created.
  ;;
  ;; Components may also have children and no content or handlers. In that case
  ;; we can just memo that we have nil content.
  (let [{: content : __cache} component
        handlers? (and component.on (not (nil? (next component.on))))
        content-type (type content)
        content-memo (case content-type
                       :nil :nil
                       :function #nil ;always stale
                       :table content
                       _ (error (Error "unsupported content type #{type}" {: type})))
        content-stale? (not (= content-memo __cache.memo))]
    (when content-stale?
      ; (Logger.info [:memoize-content {:id component.id :location component.location :stale? true}])
      (case content-type
        :nil (case handlers?
               false (do
                       (set component.__cache.memo content-memo)
                       (set component.__cache.memoized nil))
               true (do
                      (set component.__cache.memo content-memo)
                      (set component.__cache.memoized
                           (content->extmark-lines [] component.size.height))))
        :function (let [lines (-> (content)
                                  (content->extmark-lines component.size.height))]
                    (set component.__cache.memo content-type)
                    (set component.__cache.memoized lines))
        :table (let [lines (content->extmark-lines content component.size.height)]
                 (set component.__cache.memo content-memo)
                 (set component.__cache.memoized lines))))
    component.__cache.memoized))

(fn M.new [options]
  "Create a new component.

  Rendering options:

  :size {: width : height}
  :position {: row : col : z}
  :visible? true
  :content [[line] [line]]
  :children []
  :tag [:some :tag]
  :on {:click (fn ...)
       :drag (fn ...)}"
  (let [comp (doto (table.merge {:id (Id.new)
                                 :size {:width 1 :height 1}
                                 :position {:row 1 :col 1 :z 1}
                                 :tag nil
                                 ;; TODO: on -> on-input
                                 ;; copies on-event for responders but also clear that
                                 ;; we only accept input events, which I think is correct.
                                 :on {:click nil
                                      :drag nil}
                                 :visible? true
                                 :children []} options)
               (tset :in-tree? (fn [self other]
                                 (or (= self other)
                                     (accumulate [is? false
                                                  _ c (ipairs self.children)
                                                  &until is?]
                                       (c:in-tree? other)))))
               (tset :content-to-renderable memoize-content)
               (tset :invalidate-content-cache (fn [self] (set self.__cache.memo nil)))
               (tset :__cache {:memo nil :memoized nil}))]
    comp))

M

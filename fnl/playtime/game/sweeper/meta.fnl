{:name "Sweeper"
 :mod :sweeper
 :authors ["Microsoft"]
 :categories [:classic :windows]
 :rulesets [{:cli :sweeper-beginner
             :menu "Beginner (9x9, 10)"
             :config {:width 9 :height 9 :n-mines 10}}
            {:cli :sweeper-intermediate
             :menu "Intermediate (16x16, 40)"
             :config {:width 16 :height 16 :n-mines 40}}
            {:cli :sweeper-expert
             :menu "Expert (30x16, 99)"
             :config {:width 30 :height 16 :n-mines 99}}]
 :desc "The windows classic"}

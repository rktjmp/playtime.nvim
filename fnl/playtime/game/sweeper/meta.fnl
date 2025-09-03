{:name "Sweeper"
 :mod :sweeper
 :authors ["Robert Donner" "Curt Johnson"]
 :categories [:classic :win95]
 :desc "A logic puzzle video game."
 :rulesets [{:cli :sweeper-classic :menu "Sweeper Classic 8x8, 10"
             :config {:width 8 :height 8 :n-mines 10}}
            {:cli :sweeper-easy :menu "Sweeper Easy 9x9, 10"
             :config {:width 9 :height 9 :n-mines 10}}
            {:cli :sweeper-medium :menu "Sweeper Medium 16x16, 40"
             :config {:width 16 :height 16 :n-mines 40}}
            {:cli :sweeper-expert :menu "Sweeper Expert 30x16, 99"
             :config {:width 30 :height 16 :n-mines 99}}]}

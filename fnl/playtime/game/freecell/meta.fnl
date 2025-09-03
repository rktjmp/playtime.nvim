{:name "FreeCell"
 :mod :freecell
 :authors ["Paul Alfille"]
 :categories [:classic :card]
 :desc "An open-information game, made popular in the 90s by Windows 3.1+."
 :rulesets [{:cli :freecell
             :menu "Freecell"
             :config {:rules :freecell}}
            {:cli :bakers
             :menu "Bakers Game"
             :config {:rules :bakers}}]}

 ; :authors ["C. L. Baker"]
 ; :categories [:classic :card]
 ; :desc "An open-information precursor to FreeCell."

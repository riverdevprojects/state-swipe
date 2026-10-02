# Hint bank and abbreviation bonus

The offline bank contains **1,364 clues** for all 50 states. Every state has at least five distinct options at each of the five levels. Each record in `StateSwipe/states.json` has a stable ID, difficulty, title, text, cost, and source. To expand the bank, append new records to the relevant state's `hintPool` with a unique ID; no game-code change is necessary.

| Level | Rating | Cost | Examples |
| --- | --- | ---: | --- |
| 1 | Very hard | Free | Flower, bird, tree, fish, motto, exact historical date |
| 2 | Hard | 90 | Statehood year/order, Census division, name structure, lesser-known high points |
| 3 | Medium | 160 | Five different parks/landmarks per state, well-known high points |
| 4 | Easy | 250 | Capital, nickname, cities, college towns |
| 5 | Giveaway | 350 | Iconic clue, name prefix, missing vowels, scramble, alternate letters |

Ratings are editorial estimates of how helpful a clue is for identifying the state, rather than measured player success rates. Move a clue between levels by updating its `difficulty` and matching `cost`; retain at least five clues in every level. Shared symbols and broad regional facts intentionally narrow the possibilities without identifying a unique answer. Very recognizable exceptions, such as New Hampshire's motto and Alaska's highest point, appear at more helpful levels. Names embedded in symbol names are shortened to common alternatives or descriptions so they do not directly disclose the answer.

The app picks one clue per level when creating a round. It saves those choices, rotates through unused options on future visits to that state, and starts another shuffled cycle when that level's options are exhausted. The first choice of a new cycle avoids repeating the last choice of the previous cycle. Hint history is saved on the device; reinstalling resets it.

After every valid state guess, the player can enter the state's two-letter USPS code. One correct attempt doubles that round's **earned** points. A wrong code or skip keeps the original award. A wrong state guess earns zero, so its bonus is practice only. Input is case-insensitive with outer whitespace trimmed; anything other than exactly two ASCII letters does not use the attempt. A submitted or skipped bonus cannot be retried. The correct code appears after the bonus is answered or skipped. Personal bests are updated when the session ends, including bonuses. Existing personal bests and saved sessions are retained.

## Sources and editorial checks

Sources are attached to individual clues. Symbol facts and admission dates were extracted from the referenced tables, with original wording written for the game; there is no runtime network access. Primary references were used for Census divisions and exceptions.

- [State birds](https://en.wikipedia.org/wiki/List_of_U.S._state_birds)
- [State trees](https://en.wikipedia.org/wiki/List_of_U.S._state_and_territory_trees)
- [State fish](https://en.wikipedia.org/wiki/List_of_U.S._state_fish)
- [State mottos](https://en.wikipedia.org/wiki/List_of_U.S._state_and_territory_mottos)
- [Statehood order and dates](https://en.wikipedia.org/wiki/List_of_U.S._states_by_date_of_admission_to_the_Union)
- [State high points](https://en.wikipedia.org/wiki/List_of_U.S._states_and_territories_by_elevation)
- [Census divisions](https://www.census.gov/programs-surveys/economic-census/geographies/levels/2022-levels.html)
- [State flower exhibit](https://www.usbg.gov/visit/exhibits/americas-state-flowers-america250-celebration)
- [Washington's unofficial territorial motto](https://leg.wa.gov/learn-and-participate/educational-resources/state-symbols/territorial-motto/)
- [Salem Maritime's current park name](https://www.nps.gov/sama/index.htm)

No fish clue is invented for Indiana, Iowa, or Ohio, which do not have an official state fish in the reference table. Pennsylvania's ruffed grouse is labeled a game bird; Oregon's meadowlark is labeled a songbird. Multiple state trees and different fish designations are worded accordingly. The original 13 states use Constitution ratification dates, rather than claiming those dates were their first existence as states. Shared parks are described as wholly or partly in the state.

The complete bank passes automated coverage, uniqueness, difficulty/cost, selection, and persistence checks. Source links and editorial ratings remain available for future content review and playtesting.

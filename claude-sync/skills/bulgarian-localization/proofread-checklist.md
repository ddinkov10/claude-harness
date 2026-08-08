# Bulgarian Proofread Checklist

Hand this file to the proofreading subagent together with the extracted plain Bulgarian text. Every item below was violated or explicitly audited in a real project. Report findings as: location + exact current phrase + rule + exact fix + confidence (`CERTAIN` for rule violations, `SUGGESTION` for naturalness).

## Grammar

- **Пълен/кратък член.** -ът/-ят for subjects and predicate nominals after „съм“; -а/-я for objects and after prepositions. Audit EVERY masculine definite form. („Доларът е резервната валута“ but „стойността на долара“.)
- **Свършен вид.** Bare perfective present is ungrammatical in independent use — perfective verbs require „да“: „да изградиш богатство, да го заграбиш“, never „изградиш богатство, заграбиш го“.
- **Reflexive possessive.** When the possessor is the clause subject, use „свой/си“: „трупат дългове с падеж след царуването СИ“ (not „им“); „системата при старта СИ“ (not „ѝ“/„нейния“).
- **Commas.** Required after fronted subordinate/subject clauses: „Накъде текат парите, определя…“; „Какво става после, варира…“. Required before „където/който/че/защото/дали…“. NOT written between an intensifier and its conjunction: „именно че“, „точно когато“, „едва когато“.
- **Agreement.** Gender/number across nouns, adjectives, participles — especially after reordering a sentence.

## Orthography & typography

- Bulgarian quotes „…“ (U+201E open, U+201C close) — never straight `"` or English “”.
- En dash for ranges (50–75), em dash for pauses, decimal comma (−0,2%), real minus sign − (U+2212), not hyphen.
- The pronoun **ѝ must be U+045D** — never „й“ or „и“. Verify programmatically (see SKILL.md).
- Appositive noun pairs written separately per current norm: страна членка, активи застраховки, валута наследник. Hyphen only for fused units: министър-председател.
- по-/най- take a hyphen: по-привлекателно, най-силният.
- Променливо я (я/е alternation): голям → големи, бял → бели.

## Calque traps (wrong → right)

Any English idiom translated word-for-word is guilty until a native reading proves otherwise. All of these were found in the real audit:

| English | WRONG (calque) | RIGHT |
|---|---|---|
| lost to a rival | „изгубено от съперник“ (reverses the actor!) | „преминало към / в полза на съперник“ |
| doubt that you'll be paid | „съмнение, че ще ти се плати“ (asserts it!) | „съмнение дали ще ти се плати“ |
| no room to cut rates | „няма откъде да се свалят“ | „няма накъде (повече) да се свалят“ |
| trading floor | „борсов под“, „търговска зала“ | „борсова зала“ |
| relieve the squeeze | „облекчава пресата“ (= the media) | „облекчава натиска“ |
| feels good | „усеща се добре“ (= is perceptible) | „носи приятно усещане“ |
| years in advance | „години напред“ (= years to come) | „години предварително“ |
| wealth gap | „разрив“ (= rupture in relations), „разлика в богатството“ | „имуществена пропаст / имуществено неравенство“ |
| issue currency | „издавам“ (documents) | „емитирам“ |
| honor debts | „почитам/почета“ | „погасявам“ |
| the giveaway is | „издайникът е“ (= the traitor) | „издайническият знак е“ |
| someone else's | „нечий чужд“ | „чужд“ |
| borrow heavily | „заемам много“ (lend/borrow-ambiguous without „от“) | „трупам тежки дългове“ |
| gains appeal | „печели привлекателност“ | „става по-привлекателно“ |
| decision-making | „правене на решения“ | „вземане на решения“ |

## Terminology consistency (finance/economics register)

Fix ONE term per concept and hold it throughout:

резервна валута · обезценяване · фиатни пари · твърди пари · средство за съхранение на богатство · средство за размяна · масово теглене (bank run) · количествени улеснения (QE) · ливъридж · дългов цикъл

Standard anglicisms accepted in Bulgarian finance writing (фиатни, ливъридж, QE) are fine — do NOT over-purify them into awkward native coinages.

## Register

- One form of address (ти or вие), absolutely consistent.
- UI localization: option letters А/Б/В/Г, keyboard hints, „Ситуация“ for scenario labels.

## Reference

Post-proofread exemplar of tone, terminology, and typography: `const QUIZZES_BG` in `~/Dinq/TEMPLE/Principles_Quiz/index.html` (read-only).

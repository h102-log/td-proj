# 99. 만든 방법·확인 못 한 것·출처

[README](README.md)로 돌아가기.

## 만든 방법

- 2026-10-26, NAP `next/2026-10-26/r2.md`를 이어 받아 Claude 혼자 조사했다. 서브에이전트는 쓰지 않았다. 웹 검색은 19회 했다. WebFetch로 원문 페이지 7곳을 열었고 4곳은 막혔다(아래).
- 우리 게임 사실은 다음에서 읽었다. `SPEC.md`(S47·S54·S63·S104·S137·S172·S210·S211·I46·I157·I178), `src/ui/battle_view.gd`(`residents` 1565행, 그리기 507~551행, `_plan`·`_well` 1242~1291행), `src/sim/battle.gd`(`HOUSE_CAP` 18행, `tax` 855행), `data/structures/*.tres`, `tools/art/resident.py`, `tools/art/hero.py`(`save` 211행), `village_research/04_proposals.md`·`05_decisions.md`·`evidence/life_signals.md`. Godot은 띄우지 않았다.
- 직업 후보의 출발점은 NAP 6장 1번의 19개(농부·상인·대장장이 + 16개)였다. 양치기를 거위·양 지기로 넓히고, 이삭 줍기·실잣는 이·빨래·활 장인·산파·짐꾼을 더하고, 무두장이·도공·사냥꾼을 뺐다(README 1장 끝). 그래서 22개가 됐고, 사용자가 낚시꾼을 더해 23개다.

## 확인 못 한 것

- 중세 잉글랜드의 가구 유형별 비율(혼자 사는 집, 3대 동거). Laslett 표의 값은 강의 슬라이드 그림 속에 있어 숫자를 뽑지 못했다. 그래서 «약 10%»는 검색 요약이다.
- 중세 하인의 나이 분포. Hajnal 유형의 «결혼 전 하인살이»는 근세 자료가 중심이다.
- 아이 노동 나이(7~8세). 찾은 것은 대중 역사 사이트뿐이다. Hanawalt «The Ties That Bound» 원문은 보지 못했다.
- RimWorld 관계·나이·생애 단계 위키 페이지(`Relations`, `Age`, `Life_stages`)는 404였다. 생애 단계는 `Children` 페이지로 대신 봤다. 관계는 Steam 토론의 검색 요약뿐이다.
- Manor Lords 위키와 Stardew Valley 위키는 WebFetch가 403으로 막혔다. 검색 요약만 썼다.
- 24px에서 성별·나이가 읽히는지, 재질 번호 지도를 셰이더로 칠할 수 있는지는 시안에서 확인한다.

## 출처

### RimWorld와 비교작

- **S1** RimWorld Wiki, Work (원문) — https://rimworldwiki.com/wiki/Work
- **S2** RimWorld Wiki, Children (Biotech, 원문) — https://rimworldwiki.com/wiki/Children
- **S3** RimWorld Wiki, Backstories (원문, 앞 10만 자만 읽음) — https://rimworldwiki.com/wiki/Backstories
- **S24** RimWorld Wiki, Modding Tutorials/Pawn Generation Process (검색 요약) — https://rimworldwiki.com/wiki/Modding_Tutorials/Pawn_Generation_Process
- **S25** RimWorld Wiki, Skills (원문) — https://rimworldwiki.com/wiki/Skills
- **S22** RimWorld 관계에 관한 Steam 토론(검색 요약, 비공식) — https://steamcommunity.com/app/294100/discussions/0/3764481749072541811 , https://steamcommunity.com/app/294100/discussions/0/2280456883462622659
- **S20** Manor Lords Wiki, Family (검색 요약, 앞서 해보기 판 기준) — https://wiki.hoodedhorse.com/Manor_Lords/Family/pl , https://gamerguides.com/manor-lords/guide/basics/overview/getting-families-and-family-management
- **S21** Going Medieval 정착민·일 안내(검색 요약) — https://Techraptor.net/gaming/guides/going-medieval-guide-for-beginners , https://eip.gg/going-medieval/guides/jobs/
- **S23** Banished(검색 요약) — https://en.wikipedia.org/wiki/Banished_(video_game) , https://giantbomb.com/wiki/Games/Banished , https://tvtropes.org/pmwiki/pmwiki.php/Videogame/Banished
- **S15** Stardew Valley Wiki, Shane(일과, 검색 요약) — https://stardewvalleywiki.com/Shane , https://stardewvalleywiki.com/User_talk:Willblue18

### 중세 가구

- **S4** Cambridge Group for the History of Population, «Marriage in the Middle Ages»(2024, 원문) — https://www.campop.geog.cam.ac.uk/blog/2024/07/25/marriage-in-the-middle-ages/
- **S16** Laslett의 평균 가구 크기와 «핵가족 밖 친척 약 10%»(검색 요약) — https://www.encyclopedia.com/history/encyclopedias-almanacs-transcripts-and-maps/households , https://www.shortcutstv.com/wp-content/uploads/2016/11/family_fs.pdf
- **S17** 1377 인두세가 14세 미만을 세지 않음(검색 요약) — https://warwick.ac.uk/fac/soc/economics/seminars/seminars/conferences/venice3/programme/english_medieval_population.pdf
- **S18** Laslett-Hammel 가구 분류(검색 요약) — https://era.anthropology.ac.uk/Era_Resources/Era/Ascoli/ascpaper/laslett/laslett.html , https://resolve.cambridge.org/core/journals/continuity-and-change/article/leaving-home-and-the-process-of-household-formation-in-preindustrial-england/989F69D01F510D355C81953D24625F55 , Ruggles 강의 슬라이드 https://users.pop.umn.edu/~ruggl001/hist3797/Lecture%206.pdf
- **S19** Hajnal의 북서유럽 혼인 유형과 결혼 전 하인살이(검색 요약) — https://en.wikipedia.org/wiki/John_Hajnal , https://janetakesonhistory.org/2019/01/28/marriage-families-and-economic-growth/ , https://worck.quarto.pub/articles/Osthus_Uppenberg.html
- **S7** Elaine Clark, «Some Aspects of Social Security in Medieval England»(1982, 검색 요약) — https://www.medievalists.net/2011/10/some-aspects-of-social-security-in-medieval-england , https://the-orb.arlima.net/encyclop/culture/towns/florilegium/lcret_i.html

### 중세 일

- **S5** Judith Bennett, «The Village Ale-Wife»(검색 요약) — https://www.medievalists.net/2010/11/the-village-ale-wife-women-and-brewing-in-fourteenth-century-england/
- **S6** JSTOR Daily, «A Pint for the Alewives»(검색 요약) — https://daily.jstor.org/a-pint-for-the-alewives/ , https://www.Wikipedia.com/wiki/Alewife_(trade)
- **S8** 실잣기는 여성의 일(검색 요약) — https://smith.edu/hsc/museum/ancient_inventions/distaff2.html , https://thefreelancehistorywriter.com/2015/10/23/was-medieval-spinning-womens-work-a-guest-post-by-katrin-kania/ , https://www.campop.geog.cam.ac.uk/blog/2025/06/12/spinsters/
- **S9** 여성 직업(huckster, 세탁부, 1392 파리 여성 직업 172개, 검색 요약) — https://www.lauraagustin.com/scratching-out-a-living-the-medieval-female-proletariat-a-guided-walk , https://www.alpennia.com/node/3880 , https://academic.oup.com/book/2600/chapter/142966399
- **S10** 아이의 일: 거위·양 돌보기, 이삭 줍기, 7~8세(검색 요약, 대중 사이트라 약한 근거) — https://historyrise.com/article/crafts-and-skills-taught-to-medieval-children/ , https://www.mentalfloss.com/history/chores-medieval-children-were-expected-to-do
- **S11** Luttrell Psalter의 거위 지기와 거위 사육(검색 요약) — https://www.medieval.eu/the-medieval-goose/
- **S12** 마을 장인(대장장이·목수·방앗간지기·제빵사, 공동 화덕, 떠도는 이엉장이, 검색 요약, 입문 사이트라 약한 근거) — https://englishhistory.net/middle-ages/medieval-jobs/ , https://stormthecastle.com/allthingsmedieval/medieval-jobs.htm
- **S13** 1381 Bocking 인두세의 직업(목수·포목상·직조공·재단사, 검색 요약) — https://1381.online/project_outputs/cressing_rebels/narrative/
- **S14** Wikipedia, «Children's Games (Bruegel)»(원문) — https://en.wikipedia.org/wiki/Children%27s_Games_(Bruegel)


local reduce_tester = require "reduce-tester"
local test = reduce_tester.test


-- ---------------------------------------------------------------------------
-- normaler Angriff
-- ---------------------------------------------------------------------------

test('normal-gegner-verfehlt')
  .onTrigger(
    '  Der Staubdaemon greift Dich mit staubigen Fingern an.',
    '  Ein Staubdaemon verfehlt Dich.')
  .expect(':: ____normal/Fingern_____ Staubdaemon__ : Dich_________ ******** <- verfehlt')

test('normal-verfehlt')
  .onTrigger(
    '  Du greifst den Staubdaemon mit dem Kampfstock an.',
    '  Du verfehlst einen Staubdaemon.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Staubdaemon__ ******** -> verfehlt')

test('normal-gekratzt')
  .onTrigger('  Du kratzt einen Staubdaemon.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Staubdaemon__ ******** -> gekratzt')

test('normal-getroffen')
  .onTrigger('  Du triffst einen Staubdaemon.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Staubdaemon__ ******** -> getroffen')

test('normal-hart')
  .onTrigger(
    '  Du greifst den Eiselfenwaechter mit dem Kampfstock an.',
    '  Du triffst einen Eiselfenwaechter hart.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Eiselfenwaech ******** -> hart')

test('normal-sehr-hart')
  .onTrigger(
    '  Du greifst den Eiselfenwaechter mit dem Kampfstock an.',
    '  Du triffst einen Eiselfenwaechter sehr hart.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Eiselfenwaech ******** -> sehr hart')

test('normal-krachen')
  .onTrigger(
    '  Du greifst den Eiselfenwaechter mit dem Kampfstock an.',
    '  Du schlaegst einen Eiselfenwaechter mit dem Krachen brechender Knochen.')
  .expect(':: ____normal/Kampfstock__ Du___________ : Eiselfenwaech ******** -> Krachen')

-- ---------------------------------------------------------------------------
-- Spell Defend
-- ---------------------------------------------------------------------------

test('spell-defend')
  .onTrigger(
    '  Schreinemakers ihre Schwester wirft Dir ihr Mitgefuehl entgegen. ',
    'Du wehrst den Spruch ab.')
  .expect(':: ____normal/Spell_______ ???__________ : Dich_________ ******** <- DEFEND')

-- ---------------------------------------------------------------------------
-- Karate
-- ---------------------------------------------------------------------------

test('karate-fantasie')
  .onTrigger(
    '  Die Haushaelterin der Oma des Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des Schwertmeisters greift Dich mit einem wahnsinnig gut gelungenen Yoko-funaki-yamaha-fuji-wischiwaschi-sei-ko-mikado-origami-kawasaki-mawashi-geri an.',
    '  Eine Haushaelterin der Oma des Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des Schwertmeisters verfehlt Dich.')
  .expect(':: ____Karate/Yfyfwskmokmg Haushaelterin : Dich_________ ******** <- verfehlt')

test('karate-fantasie-dritte')
  .onTrigger(
    '  Die Haushaelterin der Oma des Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des Schwertmeisters greift Tutszt mit einem wahnsinnig gut gelungenen Ushiro-yamaha-origami-funaki-sei-ko-geri an.',
    '  Eine Haushaelterin der Oma des Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des Schwertmeisters trifft Tutszt sehr hart.')
  .expect(':: ____Karate/Uyofskg(+)__ Haushaelterin : Tutszt_______ ******** -- sehr hart')

test('karate-angriff-ytgk-+')
  .onTrigger(
    '  Du greifst den Leuchttroll mit einem gelungenen Yoko-tobi-geri-kekomi an.',
    '  Du schlaegst einen Leuchttroll mit dem Krachen brechender Knochen.')
  .expect(':: ____Karate/Ytgk_(+)____ Du___________ : Leuchttroll__ ******** -> Krachen')
test('karate-abwehr-hnu')
  .onTrigger(
    '  Du wehrst den Angriff mit einem Haiwan-nagashi-uke ab.',
    '  Ein Leuchttroll verfehlt Dich.')
  .expect(':: ____normal/???_________ Leuchttroll__ : Dich_________ *Hnu**** <- verfehlt')
test('karate-kombi-hnu+usu')
  .onTrigger(
    '  Du greifst den Leuchttroll mit einem mit Haiwan-nagashi-uke kombinierten Uchi-shuto-uchi an.',
    '  Du schlaegst einen Leuchttroll mit dem Krachen brechender Knochen.')
  .expect(':: Karatekomb/Hnu+Usu_____ Du___________ : Leuchttroll__ ******** -> Krachen')


-- ---------------------------------------------------------------------------
-- Chaoten
-- ---------------------------------------------------------------------------

test('chaoten-chaosball-schmettern')
  .onTrigger(
    'Du feuerst einen aetzenden Messerschnitt auf den Fuerchter-Lich ab.',
    '  Du zerschmetterst einen Fuerchter-Lich in kleine Stueckchen.')
  .expect(':: _____Chaos/Saeure+Schni Du___________ : Fuerchter-Lic ******** -> Schmettern')

test('chaoten-chaosball-schmettern-2zeilig')
  .onTrigger(
    'Du feuerst einen aetzenden Messerschnitt auf die Nachbarin des Bruders des',
    'Schwertmeisters ab.',
    '  Du zerschmetterst eine Nachbarin des Bruders des Schwertmeisters in kleine Stueckchen.')
  .expect(':: _____Chaos/Saeure+Schni Du___________ : NachbarindesB ******** -> Schmettern')

test('chaoten-chaosball-pulver-2zeilig')
  .onTrigger(
    'Du feuerst einen aetzenden Messerschnitt auf den Bruder des Schwertmeisters',
    'ab.',
    '  Du pulverisierst einen Bruder des Schwertmeisters.')
  .expect(':: _____Chaos/Saeure+Schni Du___________ : BruderdesSchw ******** -> Pulver')

test('chaoten-chaosball-brei-3zeilig')
  .onTrigger(
    'Du feuerst einen aetzenden Messerschnitt auf die Haushaelterin der Oma des',
    'Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des',
    'Schwertmeisters ab.',
    '  Du schlaegst eine Haushaelterin der Oma des Freundes der Gaertnerin der Schwester der Nachbarin des Bruders des Schwertmeisters zu Brei.')
  .expect(':: _____Chaos/Saeure+Schni Du___________ : Haushaelterin ******** -> zu Brei')

test('chaoten-tutszt-faengt')
  .onTrigger(
    'Ein Bruder des Schwertmeisters schlaegt Dich ploetzlich und voellig unerwartet',
    'mit der flachen Seite.',
    'Tutszt wirft sich in den Angriff.',
    '  Ein Bruder des Schwertmeisters trifft Dich.')
  .expect(':: _____extra/Waffenschlag BruderdesSchw : Dich_________ *Tutsz** <- getroffen')

test('chaoten-tutszt-faengt-und-helfer')
  .onTrigger(
    'Tutszt weicht dem Angriff aus.',
    'Der Kieferknochen faengt den Schlag des Gegners ab.',
    'Deine Pudelmuetze gibt ein wuetendes Bellen von sich, ein Schlaechter schaut',
    'Dich veraengstigt an.',
    'Ein Schlaechter fuerchtet sich vor Deiner Macht und zittert vor Angst!',
    '  Ein Schlaechter verfehlt Dich.')
  .expect(':: ____normal/???_________ Schlaechter__ : Dich_________ *TutszPC <- verfehlt')

test('chaoten-tutszt-angriff')
  .onTrigger(
    '  Tutszt greift den Bruder des Schwertmeisters mit Reisszaehnen und Krallen an.',
    '  Tutszt verfehlt einen Bruder des Schwertmeisters.')
  .expect(':: ____normal/Reisszaehnen Tutszt_______ : BruderdesSchw ******** -- verfehlt')

test('chaoten-tutszt-chaosball')
  .onTrigger(
    'Tutszt wirft einen Chaosball auf eine Nachbarin des Bruders des Schwertmeisters.',
    '  Tutszt trifft eine Nachbarin des Bruders des Schwertmeisters sehr hart.')
  .expect(':: ____normal/Reisszaehnen Tutszt_______ : NachbarindesB ******** -- sehr hart')

-- ---------------------------------------------------------------------------
-- Kaempfer
-- ---------------------------------------------------------------------------

test('kaempfer-schlange-kitzeln')
  .onTrigger(
    '  Der Bruder des Schwertmeisters greift Dich schlangengleich mit einem Schwert an.',
    '  Ein Bruder des Schwertmeisters kitzelt Dich am Bauch.')
  .expect(':: __Schlange/Schwert_____ BruderdesSchw : Dich_________ ******** <- gekitzelt')

test('kaempfer-ausweichen')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Bruder des Schwertmeisters.',
    'Ein Bruder des Schwertmeisters macht einen Salto rueckwaerts und entgeht so',
    'dem Angriff teilweise.',
    '  Dein Feuerstrahl trifft den Bruder des Schwertmeisters.')
  .expect(':: __Zauberei/Feuer_______ Du___________ : BruderdesSchw *Auswe** -> sehr hart')

test('kaempfer-waffenschlag1-sehr-hart-2zeilig')
  .onTrigger(
    'Ein Bruder des Schwertmeisters schlaegt Dich ploetzlich und voellig unerwartet',
    'mit der flachen Seite.',
    '  Ein Bruder des Schwertmeisters trifft Dich sehr hart.')
  .expect(':: _____extra/Waffenschlag BruderdesSchw : Dich_________ ******** <- sehr hart')

test('kaempfer-waffenschlag2-sehr-hart-2zeilig')
  .onTrigger(
    'Ein Bruder des Schwertmeisters schlaegt Dich ploetzlich und voellig unerwartet',
    'mit dem Knauf.',
    '  Ein Bruder des Schwertmeisters trifft Dich sehr hart.')
  .expect(':: _____extra/Waffenschlag BruderdesSchw : Dich_________ ******** <- sehr hart')

test('kaempfer-waffenschlag3-krachen-2zeilig')
  .onTrigger(
    'Ein Bruder des Schwertmeisters schlaegt Dich ploetzlich und voellig unerwartet',
    'mit der Parierstange.',
    '  Ein Bruder des Schwertmeisters schlaegt Dich mit dem Krachen brechender Knochen.')
  .expect(':: _____extra/Waffenschlag BruderdesSchw : Dich_________ ******** <- Krachen')

test('kaempfer-kampftritt-verfehlt')
  .onTrigger(
    'Ein Bruder des Schwertmeisters tritt Dich heimtueckisch.',
    '  Ein Bruder des Schwertmeisters verfehlt Dich.')
  .expect(':: _____extra/Kampftritt__ BruderdesSchw : Dich_________ ******** <- verfehlt')

test('kaempfer-ellbogen-verfehlt')
  .onTrigger(
    'Ein Bruder des Schwertmeisters schlaegt Dich mit seinen Ellbogen.',
    '  Ein Bruder des Schwertmeisters verfehlt Dich.')
  .expect(':: _____extra/Ellbogenschl BruderdesSchw : Dich_________ ******** <- verfehlt')

-- ---------------------------------------------------------------------------
-- Zauberer
-- ---------------------------------------------------------------------------

test('zauberer-verletze-feuer-spell-defend')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Eiselfenwaechter.',
    'Der Eiselfenwaechter wehrt Deinen Zauber ab.')
  .expect(':: __Zauberei/Feuer_______ Du___________ : Eiselfenwaech ******** -> DEFEND')

test('zauberer-verletze-feuer-krachen')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Eiselfenwaechter.',
    '  Dein Feuerstrahl trifft den Eiselfenwaechter. Es riecht verbrannt.')
  .expect(':: __Zauberei/Feuer_______ Du___________ : Eiselfenwaech ******** -> Krachen')

test('zauberer-verletze-feuer-schmettern')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Eiselfenwaechter.',
    '  Dein Feuerstrahl trifft den Eiselfenwaechter und bringt des',
    '  Eiselfenwaechters Haut zum Kokeln.')
  .expect(':: __Zauberei/Feuer_______ Du___________ : Eiselfenwaech ******** -> Schmettern')

test('zauberer-verletze-feuer-brei')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Eiselfenwaechter.',
    '  Dein Feuerstrahl macht dem Eiselfenwaechter die Hoelle heiss.')
  .expect(':: __Zauberei/Feuer_______ Du___________ : Eiselfenwaech ******** -> zu Brei')

test('zauberer-verletze-feuer-pulver')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Eiselfenwaechter.',
    '  Dein Feuerstrahl braet den Eiselfenwaechter gut durch. Steak medium!')
  .expect(':: __Zauberei/Feuer_______ Du___________ : Eiselfenwaech ******** -> Pulver')

test('zauberer-verletze-feuer-maximum-2zeilig')
  .onTrigger(
    'Du richtest einen gewaltigen Flammenstrahl auf den Bruder der Schwester des',
    'Onkels der Tante des Schwertmeisters.',
    '  Dein Feuerstrahl aeschert den Bruder der Schwester des Onkels der Tante des',
    '  Schwertmeisters einfach ein!')
  .expect(':: __Zauberei/Feuer_______ Du___________ : BruderderSchw ******** -> Maximum!')

test('zauberer-verletze-eis-defend')
  .onTrigger(
    'Du huellst den Feuerdaemon in einen Schneesturm ein.',
    'Der Feuerdaemon wehrt Deinen Zauber ab.')
  .expect(':: __Zauberei/Eis_________ Du___________ : Feuerdaemon__ ******** -> DEFEND')

test('zauberer-verletze-eis-krachen-2zeilig')
  .onTrigger(
    'Du huellst den kleinen Feuerdaemon in einen Schneesturm ein.',
    '  Du wirbelst den kleinen Feuerdaemon mit einem kleinen Schneesturm',
    '  durcheinander.')
  .expect(':: __Zauberei/Eis_________ Du___________ : Feuerdaemon__ ******** -> Krachen')

test('zauberer-verletze-eis-schmettern-2zeilig')
  .onTrigger(
    'Du huellst den Bruder des Schwertmeisters in einen Schneesturm ein.',
    '  Dein kleiner Schneesturm friert den Bruder des Schwertmeisters fast die Nase',
    '  ab.')
  .expect(':: __Zauberei/Eis_________ Du___________ : BruderdesSchw ******** -> Schmettern')

test('zauberer-verletze-eis-brei-2zeilig')
  .onTrigger(
    'Du huellst den kleinen Feuerdaemon in einen Schneesturm ein.',
    '  Dein Schneesturm schmettert Eiskristalle auf den kleinen Feuerdaemon.')
  .expect(':: __Zauberei/Eis_________ Du___________ : Feuerdaemon__ ******** -> zu Brei')

test('zauberer-verletze-eis-pulver')
  .onTrigger(
    'Du huellst den Feuerdaemon in einen Schneesturm ein.',
    '  Dein Schneesturm laesst fast des Feuerdaemons Haende abfrieren.')
  .expect(':: __Zauberei/Eis_________ Du___________ : Feuerdaemon__ ******** -> Pulver')

test('zauberer-verletze-eis-pulver-2zeilig')
  .onTrigger(
    'Du huellst den Bruder des Schwertmeisters in einen Schneesturm ein.',
    '  Dein Schneesturm laesst fast des Bruders des Schwertmeisters Haende',
    '  abfrieren.')
  .expect(':: __Zauberei/Eis_________ Du___________ : BruderdesSchw ******** -> Pulver')

test('zauberer-verletze-eis-maximum')
  .onTrigger(
    'Du huellst den Feuerdaemon in einen Schneesturm ein.',
    '  Dein Schneesturm schockgefriert den Feuerdaemon zu Staub.')
  .expect(':: __Zauberei/Eis_________ Du___________ : Feuerdaemon__ ******** -> Maximum!')

test('zauberer-verletze-magie-sehr-hart')
  .onTrigger(
    'Du huellst den Bruder des Schwertmeisters in einen Wirbel aus Funken.',
    '  Deine magischen Funken treffen den Bruder des Schwertmeisters.')
  .expect(':: __Zauberei/Magie_______ Du___________ : BruderdesSchw ******** -> sehr hart')

test('zauberer-verletze-magie-krachen')
  .onTrigger(
    'Du huellst den Bruder des Schwertmeisters in einen Wirbel aus Funken.',
    '  Deine magischen Funken lassen den Bruder des Schwertmeisters erschaudern.')
  .expect(':: __Zauberei/Magie_______ Du___________ : BruderdesSchw ******** -> Krachen')

test('zauberer-verletze-luft-brei')
  .onTrigger(
    'Du laesst eine Windhose um den Orkmagier entstehen.',
    '  Deine kleine Windhose hebt den Orkmagier zwei Meter in die Luft.')
  .expect(':: __Zauberei/Wind________ Du___________ : Orkmagier____ ******** -> zu Brei')

test('zauberer-verletze-luft-pulver')
  .onTrigger(
    'Du laesst eine Windhose um den Orkmagier entstehen.',
    '  Deine Windhose zerfetzt den Orkmagier.')
  .expect(':: __Zauberei/Wind________ Du___________ : Orkmagier____ ******** -> Pulver')

-- ---------------------------------------------------------------------------
-- Kleriker
-- ---------------------------------------------------------------------------

test('kleriker-blitz-hart')
  .onTrigger(
    'Du erhebst die Haende gen Himmel und beschwoerst einen Blitz auf einen',
    'Necromant herab.',
    '  Auf der Haut des Necromants springen kleine Funken umher.')
  .expect(':: ____Klerus/Blitz_______ Du___________ : Necromant____ ******** -> hart')

test('kleriker-blitz-sehr-hart')
  .onTrigger(
    'Du erhebst die Haende gen Himmel und beschwoerst einen Blitz auf einen',
    'Necromant herab.',
    '  Der Blitz brennt sich in den Necromant ein.')
  .expect(':: ____Klerus/Blitz_______ Du___________ : Necromant____ ******** -> sehr hart')

test('kleriker-blitz-krachen')
  .onTrigger(
    'Du erhebst die Haende gen Himmel und beschwoerst einen Blitz auf einen',
    'Necromant herab.',
    '  Der Blitz schlaegt hart in den Necromant ein.')
  .expect(':: ____Klerus/Blitz_______ Du___________ : Necromant____ ******** -> Krachen')

-- ---------------------------------------------------------------------------
-- Tanjian
-- ---------------------------------------------------------------------------

test('tanjian-arashi-sehr-hart')
  .onTrigger(
    'Du konzentrierst Dich auf die Dich umgebende Luft.',
    'Ein starker Wind kommt auf.',
    'Bewegung kommt in die Luft und Du lenkst sie auf den Eiselfenwaechter.',
    '  Ein Windhauch trifft den Eiselfenwaechter sehr hart.')
  .expect(':: ___Tanjian/Arashi______ Du___________ : Eiselfenwaech ******** -> sehr hart')

test('tanjian-arashi-krachen')
  .onTrigger(
    'Du konzentrierst Dich auf die Dich umgebende Luft.',
    'Ein starker Wind kommt auf.',
    'Bewegung kommt in die Luft und Du lenkst sie auf den Eiselfenwaechter.',
    '  Ein Windstoss schuettelt den Eiselfenwaechter durch.',
    'Der Eiselfenwaechter wirkt etwas desorientiert.')
  .expect(':: ___Tanjian/Arashi______ Du___________ : Eiselfenwaech ******** -> Krachen')

test('tanjian-arashi-schmettern')
  .onTrigger(
    'Du konzentrierst Dich auf die Dich umgebende Luft.',
    'Ein starker Wind kommt auf.',
    'Bewegung kommt in die Luft und Du lenkst sie auf den Eiselfenwaechter.',
    '  Ein Windstoss schuettelt den Eiselfenwaechter kraeftig durch.',
    'Der Eiselfenwaechter wirkt etwas desorientiert.')
  .expect(':: ___Tanjian/Arashi______ Du___________ : Eiselfenwaech ******** -> Schmettern')

test('tanjian-arashi-brei')
  .onTrigger(
    'Du konzentrierst Dich auf die Dich umgebende Luft.',
    'Ein starker Wind kommt auf.',
    'Bewegung kommt in die Luft und Du lenkst sie auf den Staubdaemon.',
    '  Eine Windboee haut den Staubdaemon um.',
    'Der Staubdaemon wirkt etwas desorientiert.')
  .expect(':: ___Tanjian/Arashi______ Du___________ : Staubdaemon__ ******** -> zu Brei')

test('tanjian-kami-fe-krachen')
  .onTrigger(
    'Du konzentrierst Dich auf den Bienenstachel.',
    'Du richtest den Bienenstachel auf den Klitzeldrom.',
    'Der Bienenstachel ist ploetzlich von einer Flammenlohe umgeben.',
    '  Ein grosser Flammenstrahl roestet den Klitzeldrom durch.')
  .expect(':: ___Tanjian/Kami.Feuer__ Du___________ : Klitzeldrom__ ******** -> Krachen')

test('tanjian-kami-fe-brei')
  .onTrigger(
    'Du konzentrierst Dich auf den Bienenstachel.',
    'Du richtest den Bienenstachel auf den Klitzeldrom.',
    'Der Bienenstachel ist ploetzlich von einer Flammenlohe umgeben.',
    '  Ein maechtiger Flammenstrahl kocht den Klitzeldrom.')
  .expect(':: ___Tanjian/Kami.Feuer__ Du___________ : Klitzeldrom__ ******** -> zu Brei')

test('tanjian-kami-fe-aescher')
  .onTrigger(
    'Du konzentrierst Dich auf den Bienenstachel.',
    'Du richtest den Bienenstachel auf den Klitzeldrom.',
    'Der Bienenstachel ist ploetzlich von einer Flammenlohe umgeben.',
    '  Ein gigantischer Flammenstrahl aeschert den Klitzeldrom ein.')
  .expect(':: ___Tanjian/Kami.Feuer__ Du___________ : Klitzeldrom__ ******** -> zerstaeubt')

-- ---------------------------------------------------------------------------
-- Dunkelelfen
-- ---------------------------------------------------------------------------

test('dunkelelfen-feuerlanze-sehr-hart')
  .onTrigger(
    'Du konzentrierst Dich auf Soeren Moerken und ploetzlich schiesst aus Deinen',
    'Fingerspitzen eine gewaltige Feuerlanze auf ihn.',
    '  Deine Feuerlanze versengt Soeren Moerken die Haut.')
  .expect(':: ____Delfen/Feuerlanze__ Du___________ : Soeren Moerke ******** -> sehr hart')

test('dunkelelfen-feuerlanze-schmettern')
  .onTrigger(
    'Du konzentrierst Dich auf Soeren Moerken und ploetzlich schiesst aus Deinen',
    'Fingerspitzen eine gewaltige Feuerlanze auf ihn.',
    '  Deine Feuerlanze schlaegt mit voller Wucht in Soeren Moerken ein.')
  .expect(':: ____Delfen/Feuerlanze__ Du___________ : Soeren Moerke ******** -> Schmettern')

-- ---------------------------------------------------------------------------
-- Abwehr-Helfer
-- ---------------------------------------------------------------------------

test('abwehr-helfer-kieferknochen')
  .onTrigger(
    '  Der Fuerchter-Lich greift Dich mit knochigen Haenden an.',
    'Der Kieferknochen faengt den Schlag des Gegners ab.',
    '  Ein Fuerchter-Lich trifft Dich.')
  .expect(':: ____normal/Haenden_____ Fuerchter-Lic : Dich_________ ***K**** <- getroffen')

test('abwehr-helfer-heiliges-kreuz')
  .onTrigger(
    'Du feuerst eine lodernde Flammenkugel auf das Wasserunwesen ab.',
    'Das Wasserunwesen lenkt Deinen Angriff ab.',
    '  Dein heiliges Kreuz faengt den Angriff ab.',
    'Deine Pudelmuetze gibt ein wuetendes Bellen von sich, ein Wasserunwesen schaut',
    'Dich veraengstigt an.',
    '  Ein Wasserunwesen trifft Dich sehr hart.')
  .expect(    ':: _____Chaos/Feuer_______ Wasserunwesen : Dich_________ *****KP* <- sehr hart')

test('abwehr-helfer-pudelmuetze')
  .onTrigger(
    '  Der Bruder des Schwertmeisters greift Dich mit dem Schwert an.',
    'Deine Pudelmuetze gibt ein wuetendes Bellen von sich, ein Bruder des',
    'Schwertmeisters schaut Dich veraengstigt an.',
    '  Ein Bruder des Schwertmeisters verfehlt Dich.')
  .expect(':: ____normal/Schwert_____ BruderdesSchw : Dich_________ ******P* <- verfehlt')

test('abwehr-helfer-eisschamanenpanzer')
  .onTrigger(
    'Der Daemon schleudert einen Feuerball nach Dir. ',
    'Der Eisschamanenpanzer unterstuetzt Deine Abwehrkraefte.',
    '  Ein Feuerdaemon trifft Dich sehr hart.')
  .expect(':: ____normal/???_________ Feuerdaemon__ : Dich_________ ****E*** <- sehr hart')

-- ---------------------------------------------------------------------------
-- Sonderfaelle
-- ---------------------------------------------------------------------------

test('schleimdrache-schleimball')
  .onTrigger(
    'Der Schleimdrache feuert einen gruenen Schleimball auf Dich ab. ',
    'Du machst einen Sprung nach hinten und weichst so dem Angriff vollstaendig',
    'aus.')
  .expect('')

-- ---------------------------------------------------------------------------
-- module definition
-- ---------------------------------------------------------------------------

return {
  run = reduce_tester.run
}


-- teddy
client.createRegexTrigger(
  '^Du verfuegst ueber \\d+/\\d+ LP \\([-+\\d]+\\) und \\d+/\\d+ KP \\([-+\\d]+\\)\\.',
  nil,
  {'g'}
)
client.createRegexTrigger('^Cool, Du hast eine leichte Vergiftung\\.$', nil, {'g'})
  
-- report
client.createRegexTrigger(
  '^Du hast jetzt \\d+ Lebenspunkte und \\d+ Konzentrationspunkte\\.',
  nil,
  {'g'}
)
client.createRegexTrigger('^Vorsicht: \\d+\\. Fluchtrichtung: .*$', nil, {'g'})
client.createRegexTrigger('^Du hast eine leichte Vergiftung\\.$', nil, {'g'})

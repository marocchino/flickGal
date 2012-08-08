
muffin = require 'muffin'
Q = require 'q'
_ = require 'underscore'



option '-w', '--watch', 'continue to watch the files and rebuild them when they change'



# Start develop.
task 'build', 'Build coffeescripts.', (options) ->
  # options = _.defaults
  #   watch: true
  # , options
  muffin.run
    files: './src/jquery.flickgal.coffee'
    options: options
    map:
      '.*?\/(jquery.flickgal).coffee': (matches) ->
        muffin.compileScript matches[0], "./#{matches[1]}.js", options



# Minify script for production use.
task 'minify', 'Minify script.', (options) ->
  muffin.run
    files: './jquery.flickgal.js'
    options: options
    map:
      '(jquery.flickgal).js': (matches) ->
        muffin.exec "uglifyjs -o jquery.flickgal.min.js jquery.flickgal.js"



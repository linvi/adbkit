Https = require 'https'

module.exports = (grunt) ->

  grunt.registerMultiTask 'keycode', 'Updates KeyEvent mapping.', ->

    repo_path = '/android/platform_frameworks_base/master'
    done = this.async()
    options = this.options
      original:
        hostname: 'raw.github.com'
        path: "#{repo_path}/core/java/android/view/KeyEvent.java"
        method: 'GET'
      regex: /public static final int (KEYCODE_[^\s]+)\s*=\s*([0-9]+);/g

    grunt.util.async.forEach this.files, (file, next) ->
      req = Https.request options.original, (res) ->
        unless res.statusCode is 200
          grunt.fail.warn \
            "Unable to retrieve KeyEvent.java (HTTP #{res.statusCode})"
          return next()

        raw = new Buffer ''

        res.on 'data', (chunk) ->
          raw = Buffer.concat [raw, chunk]

        res.on 'end', ->
          code = raw.toString()
          date = new Date().toUTCString()
          coffee = []
          coffee.push "# Generated by `grunt keycode` on #{date}"
          coffee.push ''
          coffee.push 'module.exports ='

          while match = options.regex.exec code
            coffee.push "  #{match[1]}: #{match[2]}"

          coffee.push ''

          grunt.file.write file.dest, coffee.join '\n'
          grunt.log.ok "File #{file.dest} created"

          next()

      req.on 'error', next

      req.end()

    , done
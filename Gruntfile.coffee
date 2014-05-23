module.exports = (grunt) ->
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

    # Project configuration.
    grunt.initConfig
        watch:
            options:
                atBegin: true
                nospawn: true
            test:
                options:
                    nospawn: false
                files: ['lib/{,**/}*.js', 'test/server/{,**/}*.coffee', 'test/client/{,**/}*.coffee']
                tasks: ['test']
        mochaTest:
            server:
                options:
                    reporter: 'spec'
                src: ['test/server/{,**/}*.coffee', 'test/client/{,**/}*.coffee']


    # Compile CoffeeScript, run tests, watch changes
    grunt.registerTask("default", ["watch"])
    grunt.registerTask("test", ["mochaTest"])

module.exports = (grunt) ->
    
    require('matchdep').filterDev('grunt-*').forEach(grunt.loadNpmTasks)

    # Project configuration.
    grunt.initConfig
        watch:
            options:
                atBegin: true
                nospawn: true
            coffee:
                files: 'src/{,**/}*.coffee'
                tasks: ['coffee']
            test:
                options:
                    nospawn: false
                files: ['src/{,**/}*.coffee', 'test/server/{,**/}*.coffee']
                tasks: ['mochaTest']
        coffee:
            compile:
                expand: true
                cwd: 'src'
                src: '{,**/}*.coffee'
                dest: 'lib'
                ext: '.js'
        mochaTest:
            server:
                options:
                    reporter: 'spec'
                src: ['test/server/{,**/}*.coffee']

    
    # Compile CoffeeScript, run tests, watch changes    
    grunt.registerTask("default", ["watch"])
    grunt.registerTask("test", ["coffee","mochaTest"])

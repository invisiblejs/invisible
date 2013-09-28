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
                files: ['src/{,**/}*.coffee', 'test/server/{,**/}*.coffee', 'test/client/{,**/}*.coffee']
                tasks: ['test']
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
                src: ['test/server/{,**/}*.coffee', 'test/client/{,**/}*.coffee']

    
    # Compile CoffeeScript, run tests, watch changes    
    grunt.registerTask("default", ["watch"])
    grunt.registerTask("test", ["coffee","mochaTest"])

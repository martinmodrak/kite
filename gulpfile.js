var gulp = require('gulp');
var less = require('gulp-less');
var elm  = require('gulp-elm');

// LESS compilation
gulp.task('less', function() {
    gulp.src('*.less')
        .pipe(less())
        .pipe(gulp.dest('css/'));        
});

//Elm init forces package download
gulp.task('elm-init', elm.init);

function swallowError (error) {
  this.emit('end')
}

//Build Main.elm file 
gulp.task('elm', ['elm-init'], function(){
  return gulp.src('src/Main.elm')
    .pipe(elm())
    .on('error', swallowError) //swallow errors, otherwise this stops build watching
    .pipe(gulp.dest('dist/'));
});


//Default task for development - build everything (but do not package) and watch for changes in all source files
gulp.task('default', ['less', 'elm'], function() {
    gulp.watch('*.less', ['less']);
    gulp.watch('src/*.elm', ['elm']);
})

/*
gulp.task('publish', ['less','elm'], function() {
    gulp.src(['veselka.html'])
        .pipe(replaceStep())
        .pipe(rename("index.html"))
        .pipe(replace(/"(css|img)\//g, '"../$1/'))
        .pipe(gulp.dest('dist/veselka/'))
 
    gulp.src(['index.html','reset.css','start.js'])
        .pipe(replaceStep())
        .pipe(gulp.dest('dist/'));        
    gulp.src(['css/*'])
        .pipe(gulp.dest('dist/css/'));
    gulp.src(['img/*'])
        .pipe(gulp.dest('dist/img/'));

})*/
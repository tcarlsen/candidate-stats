/*jslint indent:2, node:true, sloppy:true*/
var
  gulp = require('gulp'),
  del = require('del'),
  coffee = require('gulp-coffee'),
  ngannotate = require('gulp-ng-annotate'),
  templatecache = require('gulp-angular-templatecache'),
  rename = require("gulp-rename"),
  uglify = require('gulp-uglify'),
  sass = require('gulp-sass'),
  autoprefixer = require('gulp-autoprefixer'),
  minifycss = require('gulp-minify-css'),
  concat = require('gulp-concat'),
  imagemin = require('gulp-imagemin'),
  header = require('gulp-header'),
  cleanhtml = require('gulp-cleanhtml'),
  changed = require('gulp-changed'),
  gulpif = require('gulp-if'),
  jade = require('gulp-jade'),
  connect = require('gulp-connect'),
  plumber = require('gulp-plumber'),
  sourcemaps = require('gulp-sourcemaps'),

  pkg = require('./package.json');

var banner = [
  '/**',
  ' ** <%= pkg.name %> - <%= pkg.description %>',
  ' ** @author <%= pkg.author %>',
  ' ** @version v<%= pkg.version %>',
  ' **/',
  ''
].join('\n');

var build = false;
var dest = 'app';
/* Scripts */
gulp.task('scripts', function () {
  return gulp.src('src/**/*.coffee')
    .pipe(plumber())
    .pipe(gulpif(!build, changed(dest)))
    .pipe(gulpif(!build, sourcemaps.init()))
    .pipe(concat('source.js'))
    .pipe(coffee())
    .pipe(ngannotate())
    .pipe(uglify())
    .pipe(gulpif(!build, sourcemaps.write()))
    .pipe(gulpif(build, header(banner, {pkg: pkg})))
    .pipe(gulp.dest('.tmp'));
});
/* Styles */
gulp.task('styles', function () {
  return gulp.src('src/styles/app.scss')
    .pipe(plumber())
    .pipe(gulpif(!build, changed(dest)))
    .pipe(gulpif(!build, sourcemaps.init()))
    .pipe(concat('styles.min.css'))
    .pipe(sass())
    .pipe(autoprefixer())
    .pipe(minifycss())
    .pipe(gulpif(!build, sourcemaps.write()))
    .pipe(gulpif(build, header(banner, {pkg: pkg})))
    .pipe(gulp.dest(dest))
    .pipe(connect.reload());
});
/* Dom elements */
gulp.task('dom', function () {
  return gulp.src('src/**/*.jade')
    .pipe(plumber())
    .pipe(gulpif(!build, changed(dest)))
    .pipe(jade({pretty: true}))
    .pipe(gulpif(build, cleanhtml()))
    .pipe(rename({dirname: '/'}))
    .pipe(templatecache({standalone: true}))
    .pipe(gulp.dest('.tmp'));
});
/* Merge scripts */
gulp.task('merge-scripts', ['dom', 'scripts'], function () {
  return gulp.src('.tmp/*.js')
    .pipe(plumber())
    .pipe(concat('scripts.min.js'))
    .pipe(gulp.dest(dest))
    .pipe(connect.reload());
});
/* Watch task */
gulp.task('watch', function () {
  gulp.watch(['src/**/*.coffee', 'src/**/*.jade'], ['merge-scripts']);
  gulp.watch('src/**/*.scss', ['styles']);
  gulp.watch('src/images/**', ['images']);
});
/* Server */
gulp.task('connect', function () {
  connect.server({
    root: ['app', 'node_modules'],
    port: 9000,
    livereload: true
  });
});
/* CORS Proxy */
gulp.task('corsproxy', function () {
  require('corsproxy/bin/index');
});
/* Build task */
gulp.task('build', function () {
  build = true;
  dest = 'build';

  del(dest);
  gulp.start('merge-scripts', 'styles');
});
/* Default task */
gulp.task('default', ['corsproxy', 'connect', 'merge-scripts', 'styles', 'watch']);

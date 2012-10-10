#!perl -w
use strict;
use warnings;
use utf8;
use Data::Dumper;

my $app = sub {
  my $env = shift;
  my $method = uc $env->{REQUEST_METHOD};
  my $path = $env->{PATH_INFO};
  my $q = $env->{QUERY_STRING} || "/";
  my $status = 200;
  my $head = ['Content-Type'=>'text/plain']; 
  my $body = "200 ok $path";
  if ( $method eq 'OPTIONS' ) {
    if ( $path eq '/allow' ) {
      $status = 200;
      $head = [
               'Allow' => 'GET, OPTIONS',
               'Access-Control-Allow-Origin' => '*',
               'Access-Control-Allow-Headers' => 'x-prototype-version,x-requested-with'
              ];
      $body = "";
    } 
    else {
      $status = 405;
      $head = ['Content-Type' => 'text/plain'];
      $body = '405 method not allowed';
    }
  }
  else {
    if ( $path eq '/' ) {
      $status = 200;
      $head = ['Content-Type' => 'text/html'];
      $body = "";
      while (<DATA>) { $body .= $_; }
    }
    if ( $path eq '/r' ) {
      $status = 301;
      $head = ['Location' => $q ];
      $body = $q;
    }
    if ( $path eq '/allow' ) {
      $status = 200;
      $head = [
               'Access-Control-Allow-Origin' => '*',
               'Access-Control-Allow-Headers' => 'x-prototype-version,x-requested-with'
              ];
    }
  }

  return [$status, $head, [$body]];
};

return $app;

__DATA__
<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>test</title>
    <style>div{ border: 1px solid green; }</style>
  </head>
  <body>
    <ul>
      <li>p1 : xhr.get('/samaorigin'); should success</li>
      <li>p2 : xhr.get('http://otherorigin/allowed.content'); with preflight should success</li>
      <li>p3 : xhr.get('http://otherorigin/not.allowed.content'); with preflight should failed</li>
      <li>p4 : xhr.get('/redirect?otherorigin/allowed'); </li>
      <li>p5 : xhr.get('/redirect?otherorigin/notallowed'); should failed</li>
    </ul>
    <button id="a">p1</button><button id="b">p2</button><button id="c">p3</button><button id="d">p4</button><button id="e">p5</button>
    <div id="ra"></div><div id="rb"></div><div id="rc"></div><div id="rd"></div><div id="re"></div>
    <script>
      function $(id){ return document.getElementById(id); }
      function xhr(url, cb) { 
        var x = new XMLHttpRequest();
        x.open('GET', url, true);
        x.setRequestHeader('X-Requested-With','XMLHttpRequest');
        x.onreadystatechange = function(){ cb(x); };
        x.send(null);
      }
      function cls(id){ $(id).innerHTML = ''; }
      function log(id, msg){
        var p = document.createElement('p');
        p.appendChild(document.createTextNode(msg));
        $(id).appendChild(p);
      }
      function cbb(id){ return function (x){ log(id, x.readyState + ':' + JSON.stringify(x)); }; }
      window.onload = function(){
        var another = 'http://' + location.hostname + ':5050';
        $('a').onclick = function(){ cls('ra'); var url = '/same'; log('ra', url ); xhr( url, cbb('ra')); };
        $('b').onclick = function(){ cls('rb'); var url = another + '/allow'; log('rb', url); xhr( url, cbb('rb') ); };
        $('c').onclick = function(){ cls('rc'); var url = another + '/notallow'; log('rc', url); xhr(url, cbb('rc') ); };
        $('d').onclick = function(){ cls('rd'); var url = '/r?' + another + '/allow'; log('rd', url); xhr(url, cbb('rd') ); };
        $('e').onclick = function(){ cls('re'); var url = '/r?' + another + '/notallow'; log('re',url); xhr(url, cbb('re') ); };
      };
    </script>
  </body>
</html>

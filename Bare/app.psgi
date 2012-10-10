use strict;
use warnings;
use utf8;
use File::Spec;
use File::Basename;
use lib File::Spec->catdir(dirname(__FILE__), 'extlib', 'lib', 'perl5');
use lib File::Spec->catdir(dirname(__FILE__), 'lib');
use Amon2::Lite;

our $VERSION = '0.01';

get '/' => sub {
  my $c = shift;
  return $c->render('index.tt');
};

get '/{status}/{ppp:.*}' => sub { 
  my ($c, $a) = @_;
  my $s = int($a->{status});
  my $p = $a->{ppp};
  if ($s >= 300 && $s <= 399){
    return $c->create_response( $s, ['Location' => $p], [] );
  }  
  return $c->create_response( 200, ['Content-Type' => 'text/plain'], [$s . "\n" . $p ] );
};

any [qw/options get/] => '/{any}' => sub {
  my ($c, $a) = @_;
  return $c->create_response( 
                             200, 
                             [ 'Content-Type' => 'text/plain',
                               'Allow' => 'GET, OPTIONS',
                               'Access-Control-Allow-Origin' => '*',
                               'Access-Control-Allow-Headers' => 'x-prototype-version,x-requested-with', 
                             ], 
                             ['200 ok ' . $a->{any}]);
};

__PACKAGE__->to_app(handle_static => 1);

__DATA__

@@ index.tt
<!doctype html>
<html>
  <head>
    <meta charset="utf-8"/>
    <title>test</title>
  </head>
  <body>
    <button id="a">xhr.get same origin page</button>
    <button id="b">xhr.get other origin page</button>
    <button id="c">xhr.get other origin page + via 301</button>
    <div id="ra"></div>
    <div id="rb"></div>
    <div id="rc"></div>
    <script>
      function $(id){ return document.getElementById(id); }
      function xhr(url, cb) { 
        var x = new XMLHttpRequest();
        x.open('GET', url, true);
        x.setRequestHeader('X-Requested-With','XMLHttpRequest');
        x.onreadystatechange = function(){ cb(x); };
        x.send(null);
      }
      function cls(id){
        $(id).innerHTML = '';
      }
      function log(id, msg){
        var p = document.createElement('pre');
        p.appendChild(document.createTextNode(msg));
        $(id).appendChild(p);
      }
      function cbb(id){
        return function (x){ 
          log(id, x.readyState + ':' + JSON.stringify(x));
        };
      }
      window.onload = function(){
        var another = 'http://' + location.hostname + ':5050';
        $('a').onclick = function(){ cls('ra'); xhr('/same', cbb('ra')); };
        $('b').onclick = function(){ cls('rb'); xhr(another + '/cross1', cbb('rb') ); };
        $('c').onclick = function(){ cls('rc'); xhr('/301/' + another + '/cross2', cbb('rc') ); };
      };
    </script>
  </body>
</html>

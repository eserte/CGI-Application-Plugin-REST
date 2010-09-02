#!/usr/bin/perl

# Test REST routing
use strict;
use warnings;
use English qw( -no_match_vars );
use Test::More tests => 20;
use Test::WWW::Mechanize::CGIApp;
use lib 't/lib';
use Test::CAPREST;

my $mech = Test::WWW::Mechanize::CGIApp->new;

$mech->app(
    sub {
        my $app = Test::CAPREST->new(PARAMS => {

        });
        $app->run();
    }
);
$mech->add_header(Accept => 'text/html;q=1.0, */*;q=0.1');

$mech->get('http://localhost/foo');
$mech->title_is('No parameters', 'route with no parameters');

$mech->get('http://localhost/bar/mark/76/mark@stosberg.com');
$mech->title_is('mark@stosberg.com mark 76', 'route with parameters');

$mech->get('http://localhost/bar/mark/mark@stosberg.com');
$mech->title_is('mark@stosberg.com mark', 'route with a missing parameter');

eval {
    $mech->get('http://localhost/bar/mark/76/mark@stosberg.com?nodispatch=1');
};
ok(defined $EVAL_ERROR, 'no dispatch table');

eval {
    $mech->get('http://localhost/bar/mark/76/mark@stosberg.com?bogusdispatch=1');
};
ok(defined $EVAL_ERROR, 'incomplete dispatch table');

$mech->get('http://localhost/bogus/mark/76/mark@stosberg.com');
$mech->title_is('default', 'non-existent route');

$mech->get('http://localhost/baz/string/good/');
$mech->title_is('good', 'route with a wildcard parameter');

$mech->get('http://localhost/baz/string/evil/');
$mech->title_is('evil', 'route with a a different wildcard parameter');

$mech->get('http://localhost/quux');
$mech->title_is('8', 'rest_route return value');

eval {
    $mech->post('http://localhost/quux', content_type => 'text/html');
};
ok($EVAL_ERROR, 'request method not allowed');

eval {
    $mech->post('http://localhost/quux?_method=delete', content => q{});
};
ok($EVAL_ERROR, 'method not implemented');

eval {
    $mech->get('http://localhost/zing?bogusroute=1');
};
ok($EVAL_ERROR, 'route is wrong data type');

eval {
    $mech->get('http://localhost/zing?bogusmethod=1');
};
ok($EVAL_ERROR, 'method not recognized');

$mech->post('http://localhost/edna', content => q{}, content_type => 'text/html');
$mech->title_is('blip', 'specific method when wildcard exists');

$mech->get('http://localhost/edna');
$mech->title_is('blop', 'wildcard method');

$mech->add_header(Accept => 'application/xml;q=1.0, */*;q=0.1');

$mech->get('http://localhost/grudnuk');
$mech->title_is('zip', 'dispatch by mimetype');

$mech->put('http://localhost/grudnuk', content_type => 'application/xml');
$mech->title_is('zoom', 'wildcard method');

eval {
    $mech->get('http://localhost/zing?bogussubroute=1',);
};
ok($EVAL_ERROR, 'invalid subroute_type');

eval {
$mech->put('http://localhost/grudnuk', content => q{}, content_type => 'image/gif');
};
ok($EVAL_ERROR, 'unsupported content_type');

$mech->get('http://localhost/arf');
$mech->title_is('zap', 'subroute is not a hashref');

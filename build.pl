#!/usr/bin/env perl
#-*-Mode:perl;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
# ex: set ft=perl fenc=utf-8 sts=4 ts=4 sw=4 et:

use strict;
use warnings;

require Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Erlang',
    license             => 'bsd',
    dist_abstract       => 'Erlang Binary Term Format for Perl',
    dist_author         => 'Michael Truog <mjtruog@gmail.com>',
    build_requires => {
        'Compress::Zlib' => '>= 2.020',
        'POSIX' => '>= 1.17',
        'Test::More' => '>= 0.92',
    },
);

$builder->create_build_script();

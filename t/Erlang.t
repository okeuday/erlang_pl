#!/usr/bin/env perl
#-*-Mode:perl;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
# ex: set ft=perl fenc=utf-8 sts=4 ts=4 sw=4 et:
#
# BSD LICENSE
# 
# Copyright (c) 2014, Michael Truog <mjtruog at gmail dot com>
# Copyright (c) 2009-2013, Dmitry Vasiliev <dima@hlabs.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in
#       the documentation and/or other materials provided with the
#       distribution.
#     * All advertising materials mentioning features or use of this
#       software must display the following acknowledgment:
#         This product includes software developed by Michael Truog
#     * The name of the author may not be used to endorse or promote
#       products derived from this software without specific prior
#       written permission
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
# CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
# DAMAGE.
#

use strict;
use warnings;

use Test::More qw(no_plan);

BEGIN { use_ok('Erlang') };
require_ok('Erlang');
require_ok('Erlang::OtpErlangAtom');
require_ok('Erlang::OtpErlangList');
require_ok('Erlang::OtpErlangBinary');
require_ok('Erlang::OtpErlangFunction');
require_ok('Erlang::OtpErlangReference');
require_ok('Erlang::OtpErlangPort');
require_ok('Erlang::OtpErlangPid');
require_ok('Erlang::ParseException');
require_ok('Erlang::InputException');
require_ok('Erlang::OutputException');

# many of the test cases were adapted
# from erlport (https://github.com/hdima/erlport)
# to make the tests more exhaustive

sub is_exception
{
    my $code = \&{shift @_};
    my ($name, $message) = @_;
    eval
    {
        $code->();
    };
    my $e = $@;
    ok($e);
    isa_ok($e, $name);
    if (defined $message)
    {
        is($e->{message}, $message);
    }
}

# AtomTestCase, test_atom
{
    my $atom1 = Erlang::OtpErlangAtom->new('test');
    isa_ok($atom1, 'Erlang::OtpErlangAtom');
    is_deeply(Erlang::OtpErlangAtom->new('test'), $atom1);
    is('Erlang::OtpErlangAtom(test,0)', "$atom1");
    my $atom2 = Erlang::OtpErlangAtom->new('test2');
    my $atom1_new = Erlang::OtpErlangAtom->new('test');
    ok("$atom1" ne "$atom2");
    is_deeply($atom1, $atom1_new);
    my $atom3 = Erlang::OtpErlangAtom->new('X' x 256);
    is('X' x 256, $atom3->{value});
}
# AtomTestCase, test_invalid_atom
{
    is_exception(sub
        {
            my $atom_invalid = Erlang::OtpErlangAtom->new([1, 2]);
            $atom_invalid->binary();
        }, 'Erlang::OutputException', 'unknown atom type');
}
# ListTestCase, test_list
{
    my @values = (116, 101, 115, 116);
    my $lst = Erlang::OtpErlangList->new(\@values);
    isa_ok($lst, 'Erlang::OtpErlangList');
    is_deeply(Erlang::OtpErlangList->new([116, 101, 115, 116]), $lst);
    my $lst_values_got_ref = $lst->{value};
    my @lst_values_got = @$lst_values_got_ref;
    my @lst_values_expected = (116, 101, 115, 116);
    is_deeply(\@lst_values_got, \@lst_values_expected);
    my $lst_new = Erlang::OtpErlangList->new([116, 101, 115, 116]);
    is("$lst", 'Erlang::OtpErlangList([116,101,115,116],0)');
    is("$lst", "$lst_new");
}
# ImproperListTestCase, test_improper_list
{
    my $lst = Erlang::OtpErlangList->new([1, 2, 3, 4], 1);
    isa_ok($lst, 'Erlang::OtpErlangList');
    my $lst_values_got_ref = $lst->{value};
    my @lst_values_got = @$lst_values_got_ref;
    my @lst_values_expected = (1, 2, 3, 4);
    is_deeply(\@lst_values_got, \@lst_values_expected);
    is(scalar(@lst_values_got), 4);
    is("$lst", 'Erlang::OtpErlangList([1,2,3,4],1)');
}
# ImproperListTestCase, test_comparison
{
    my $lst = Erlang::OtpErlangList->new([1, 2, 3, 4], 1);
    is_deeply($lst, $lst);
    is_deeply(Erlang::OtpErlangList->new([1, 2, 3, 4], 1), $lst);
    my $lst_mismatch1 = Erlang::OtpErlangList->new([1, 2, 3, 4, 5], 1);
    isnt("$lst", "$lst_mismatch1");
    my $lst_mismatch2 = Erlang::OtpErlangList->new([1, 2, 3], 1);
    isnt("$lst", "$lst_mismatch2");
}
# ImproperListTestCase, test_errors
{
    is_exception(sub
        {
            my $list_invalid = Erlang::OtpErlangList->new('invalid', 1);
            $list_invalid->binary();
        }, 'Erlang::OutputException', 'unknown list type');
}
# DecodeTestCase, test_binary_to_term
{
    is_exception(sub
        {
            Erlang::binary_to_term('');
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83z");
        }, 'Erlang::ParseException');
}
# DecodeTestCase, test_binary_to_term_atom
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83d");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83d\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83d\0\1");
        }, 'Erlang::ParseException');
    is_deeply(Erlang::OtpErlangAtom->new(''),
              Erlang::binary_to_term("\x83d\0\0"));
    is_deeply(Erlang::OtpErlangAtom->new(''),
              Erlang::binary_to_term("\x83s\0"));
    is_deeply(Erlang::OtpErlangAtom->new('test'),
              Erlang::binary_to_term("\x83d\0\4test"));
    is_deeply(Erlang::OtpErlangAtom->new('test'),
              Erlang::binary_to_term("\x83s\4test"));
}
# DecodeTestCase, test_binary_to_term_predefined_atoms
{
    is_deeply(Erlang::OtpErlangAtom->new('true'),
              Erlang::binary_to_term("\x83s\4true"));
    is_deeply(Erlang::OtpErlangAtom->new('false'),
              Erlang::binary_to_term("\x83s\5false"));
    is_deeply(Erlang::OtpErlangAtom->new('undefined'),
              Erlang::binary_to_term("\x83d\0\11undefined"));
}
# DecodeTestCase, test_binary_to_term_empty_list
{
    is_deeply(Erlang::OtpErlangList->new([]),
              Erlang::binary_to_term("\x83j"));
}
# DecodeTestCase, test_binary_to_term_string_list
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l\0\0\0\0");
        }, 'Erlang::ParseException');
    my $lst = Erlang::binary_to_term("\x83l\0\0\0\0j");
    is("$lst","Erlang::OtpErlangList([],0)");
    is_deeply(Erlang::OtpErlangList->new([]),
              Erlang::binary_to_term("\x83l\0\0\0\0j"));
    is_deeply(Erlang::OtpErlangList->new([
                  Erlang::OtpErlangList->new([]),
                  Erlang::OtpErlangList->new([])]),
              Erlang::binary_to_term("\x83l\0\0\0\2jjj"));
    
}
# DecodeTestCase, test_binary_to_term_improper_list
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83l\0\0\0\0k");
        }, 'Erlang::ParseException');
    my $lst = Erlang::binary_to_term("\x83l\0\0\0\1jd\0\4tail");
    isa_ok($lst, 'Erlang::OtpErlangList');
    my $lst_value_ref = $lst->{value};
    my @lst_value = @$lst_value_ref;
    is_deeply([Erlang::OtpErlangList->new([]),
               Erlang::OtpErlangAtom->new('tail')], \@lst_value);
    is(1, $lst->{improper});
}
# DecodeTestCase, test_binary_to_term_small_tuple
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83h");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83h\1");
        }, 'Erlang::ParseException');
    #my $tuple = Erlang::binary_to_term("\x83h\0");
    #is(ref($tuple), 'ARRAY');
}

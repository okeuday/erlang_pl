#!/usr/bin/env perl
#-*-Mode:perl;coding:utf-8;tab-width:4;c-basic-offset:4;indent-tabs-mode:()-*-
# ex: set ft=perl fenc=utf-8 sts=4 ts=4 sw=4 et nomod:
#
# MIT License
#
# Copyright (c) 2014-2018 Michael Truog <mjtruog at protonmail dot com>
# Copyright (c) 2009-2013, Dmitry Vasiliev <dima@hlabs.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.
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
require_ok('Erlang::OtpErlangString');
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
    is("Erlang::OtpErlangList([],0)", "$lst");
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
    my $tuple = Erlang::binary_to_term("\x83h\0");
    is(ref($tuple), 'ARRAY');
    is(scalar(@$tuple), 0);
    is_deeply($tuple, []);
    is_deeply([Erlang::OtpErlangList->new([]),
               Erlang::OtpErlangList->new([])],
              Erlang::binary_to_term("\x83h\2jj"));
}
# DecodeTestCase, test_binary_to_term_large_tuple
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83i");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83i\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83i\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83i\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83i\0\0\0\1");
        }, 'Erlang::ParseException');
    my $tuple = Erlang::binary_to_term("\x83i\0\0\0\0");
    is(ref($tuple), 'ARRAY');
    is(scalar(@$tuple), 0);
    is_deeply($tuple, []);
    is_deeply([Erlang::OtpErlangList->new([]),
               Erlang::OtpErlangList->new([])],
              Erlang::binary_to_term("\x83i\0\0\0\2jj"));
}
# DecodeTestCase, test_binary_to_term_small_integer
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83a");
        }, 'Erlang::ParseException');
    is(0, Erlang::binary_to_term("\x83a\0"));
    is(255, Erlang::binary_to_term("\x83a\xff"));
}
# DecodeTestCase, test_binary_to_term_integer
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83b");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83b\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83b\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83b\0\0\0");
        }, 'Erlang::ParseException');
    is(0, Erlang::binary_to_term("\x83b\0\0\0\0"));
    is(2147483647, Erlang::binary_to_term("\x83b\x7f\xff\xff\xff"));
    is(-2147483648, Erlang::binary_to_term("\x83b\x80\x00\x00\x00"));
    is(-1, Erlang::binary_to_term("\x83b\xff\xff\xff\xff"));
}
# DecodeTestCase, test_binary_to_term_binary
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83m");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83m\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83m\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83m\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83m\0\0\0\1");
        }, 'Erlang::ParseException');
    is_deeply(Erlang::OtpErlangBinary->new(''),
              Erlang::binary_to_term("\x83m\0\0\0\0"));
    is_deeply(Erlang::OtpErlangBinary->new('data'),
              Erlang::binary_to_term("\x83m\0\0\0\4data"));
}
# DecodeTestCase, test_binary_to_term_float
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0\0\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83F\0\0\0\0\0\0\0");
        }, 'Erlang::ParseException');
    is_deeply(0.0, Erlang::binary_to_term("\x83F\0\0\0\0\0\0\0\0"));
    is_deeply(1.5, Erlang::binary_to_term("\x83F?\xf8\0\0\0\0\0\0"));
}
# DecodeTestCase, test_binary_to_term_small_big_integer
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83n");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83n\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83n\1\0");
        }, 'Erlang::ParseException');
    is_deeply(0, Erlang::binary_to_term("\x83n\0\0"));
    is_deeply(6618611909121, Erlang::binary_to_term("\x83n\6\0\1\2\3\4\5\6"));
    is_deeply(-6618611909121, Erlang::binary_to_term("\x83n\6\1\1\2\3\4\5\6"));
}
# DecodeTestCase, test_binary_to_term_big_integer
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o\0\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83o\0\0\0\1\0");
        }, 'Erlang::ParseException');
    is_deeply(0, Erlang::binary_to_term("\x83o\0\0\0\0\0"));
    is_deeply(6618611909121,
              Erlang::binary_to_term("\x83o\0\0\0\6\0\1\2\3\4\5\6"));
    is_deeply(-6618611909121,
              Erlang::binary_to_term("\x83o\0\0\0\6\1\1\2\3\4\5\6"));
}
# DecodeTestCase, test_binary_to_term_compressed_term
{
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P\0\0\0\0");
        }, 'Erlang::ParseException');
    is_exception(sub
        {
            Erlang::binary_to_term("\x83P\0\0\0\x16\x78\xda\xcb\x66" .
                                   "\x10\x49\xc1\2\0\x5d\x60\x08\x50");
        }, 'Erlang::ParseException');
    is('d' x 20, Erlang::binary_to_term("\x83P\0\0\0\x17\x78\xda\xcb\x66" .
                                        "\x10\x49\xc1\2\0\x5d\x60\x08\x50"));
}
# EncodeTestCase, test_term_to_binary_tuple
{
    is("\x83h\0", Erlang::term_to_binary([]));
    is("\x83h\2h\0h\0", Erlang::term_to_binary([[], []]));
    my @tuple_255 = ([]) x 255;
    is("\x83h\xff" . ("h\0" x 255), Erlang::term_to_binary(\@tuple_255));
    my @tuple_256 = ([]) x 256;
    is("\x83i\0\0\1\0" . ("h\0" x 256), Erlang::term_to_binary(\@tuple_256));
}
# EncodeTestCase, test_term_to_binary_empty_list
{
    is("\x83j", Erlang::term_to_binary(Erlang::OtpErlangList->new([])));
}
# EncodeTestCase, test_term_to_binary_string_list
{
    is("\x83k\0\1\0", Erlang::term_to_binary("\0"));
    my $s = '';
    for my $c (0 .. 256 - 1)
    {
        $s .= chr($c);
    }
    is("\x83k\1\0" . $s, Erlang::term_to_binary($s));
}
# EncodeTestCase, test_term_to_binary_list_basic
{
    is("\x83\x6A", Erlang::term_to_binary(Erlang::OtpErlangList->new([])));
    is("\x83\x6C\x00\x00\x00\x01\x6A\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([''])));
    is("\x83\x6C\x00\x00\x00\x01\x61\x01\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([1])));
    is("\x83\x6C\x00\x00\x00\x01\x61\xFF\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([255])));
    is("\x83\x6C\x00\x00\x00\x01\x62\x00\x00\x01\x00\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([256])));
    is("\x83\x6C\x00\x00\x00\x01\x62\x7F\xFF\xFF\xFF\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([2147483647])));
    is("\x83\x6C\x00\x00\x00\x01\x6E\x04\x00\x00\x00\x00\x80\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([2147483648])));
    is("\x83\x6C\x00\x00\x00\x01\x61\x00\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([0])));
    is("\x83\x6C\x00\x00\x00\x01\x62\xFF\xFF\xFF\xFF\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([-1])));
    is("\x83\x6C\x00\x00\x00\x01\x62\xFF\xFF\xFF\x00\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([-256])));
    is("\x83\x6C\x00\x00\x00\x01\x62\xFF\xFF\xFE\xFF\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([-257])));
    is("\x83\x6C\x00\x00\x00\x01\x62\x80\x00\x00\x00\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([-2147483648])));
    is("\x83\x6C\x00\x00\x00\x01\x6E\x04\x01\x01\x00\x00\x80\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([-2147483649])));
    is("\x83\x6C\x00\x00\x00\x01\x6B\x00\x04\x74\x65\x73\x74\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new(['test'])));
    is("\x83\x6C\x00\x00\x00\x02\x62\x00\x00\x01\x75\x62\x00\x00" .
       "\x01\xC7\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([373, 455])));
    is("\x83\x6C\x00\x00\x00\x01\x6A\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([
           Erlang::OtpErlangList->new([])])));
    is("\x83\x6C\x00\x00\x00\x03\x6C\x00\x00\x00\x02\x6B\x00\x04\x74\x68" .
       "\x69\x73\x6B\x00\x02\x69\x73\x6A\x6C\x00\x00\x00\x01\x6C\x00\x00" .
       "\x00\x01\x6B\x00\x01\x61\x6A\x6A\x6B\x00\x04\x74\x65\x73\x74\x6A",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([
           Erlang::OtpErlangList->new(['this', 'is']),
           Erlang::OtpErlangList->new([
               Erlang::OtpErlangList->new(['a'])]),
           'test'])));
}
# EncodeTestCase, test_term_to_binary_list
{
    is("\x83l\0\0\0\1jj",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([
           Erlang::OtpErlangList->new([])])));
    is("\x83l\0\0\0\5jjjjjj",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([
           Erlang::OtpErlangList->new([]),
           Erlang::OtpErlangList->new([]),
           Erlang::OtpErlangList->new([]),
           Erlang::OtpErlangList->new([]),
           Erlang::OtpErlangList->new([])])));
}
# EncodeTestCase, test_term_to_binary_improper_list
{
    is("\x83l\0\0\0\1h\0h\0",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([[], []], 1)));
    is("\x83l\0\0\0\1a\0a\1",
       Erlang::term_to_binary(Erlang::OtpErlangList->new([0, 1], 1)));
}
# EncodeTestCase, test_term_to_binary_atom
{
    is("\x83s\0",
       Erlang::term_to_binary(Erlang::OtpErlangAtom->new('')));
    is("\x83s\4test",
       Erlang::term_to_binary(Erlang::OtpErlangAtom->new('test')));
}
# EncodeTestCase, test_term_to_binary_string_basic
{
    is("\x83\x6A", Erlang::term_to_binary(''));
    is("\x83\x6B\x00\x04\x74\x65\x73\x74", Erlang::term_to_binary('test'));
    is("\x83\x6B\x00\x09\x74\x77\x6F\x20\x77\x6F\x72\x64\x73",
       Erlang::term_to_binary('two words'));
    is("\x83\x6B\x00\x16\x74\x65\x73\x74\x69\x6E\x67\x20\x6D\x75\x6C\x74" .
       "\x69\x70\x6C\x65\x20\x77\x6F\x72\x64\x73",
       Erlang::term_to_binary('testing multiple words'));
    is("\x83\x6B\x00\x01\x20", Erlang::term_to_binary(' '));
    is("\x83\x6B\x00\x02\x20\x20", Erlang::term_to_binary('  '));
    # due to perl, numbers in string form are interpreted as integers
    # Erlang::OtpErlangString objects provide a way to work around the problem
    is("\x83\x6B\x00\x01\x31",
       Erlang::term_to_binary(Erlang::OtpErlangString->new('1')));
    is("\x83\x6B\x00\x02\x33\x37",
       Erlang::term_to_binary(Erlang::OtpErlangString->new('37')));
    is("\x83\x6B\x00\x07\x6F\x6E\x65\x20\x3D\x20\x31",
       Erlang::term_to_binary('one = 1'));
    is("\x83\x6B\x00\x20\x21\x40\x23\x24\x25\x5E\x26\x2A\x28\x29\x5F\x2B" .
       "\x2D\x3D\x5B\x5D\x7B\x7D\x5C\x7C\x3B\x27\x3A\x22\x2C\x2E\x2F\x3C" .
       "\x3E\x3F\x7E\x60",
       Erlang::term_to_binary("!@#\$%^&*()_+-=[]{}\\|;':\",./<>?~`"));
    is("\x83\x6B\x00\x09\x22\x08\x0C\x0A\x0D\x09\x0B\x53\x12",
       Erlang::term_to_binary("\"\x08\f\n\r\t\x0b\123\x12"));
}
# EncodeTestCase, test_term_to_binary_string
{
    is("\x83j", Erlang::term_to_binary(''));
    is("\x83k\0\1\0", Erlang::term_to_binary("\0"));
    is("\x83k\0\4test", Erlang::term_to_binary('test'));
}
# EncodeTestCase, test_term_to_binary_predefined_atoms
{
    is("\x83s\4true",
       Erlang::term_to_binary(Erlang::OtpErlangAtom->new('true')));
    is("\x83s\5false",
       Erlang::term_to_binary(Erlang::OtpErlangAtom->new('false')));
    is("\x83s\x09undefined", Erlang::term_to_binary(undef));
}
# EncodeTestCase, test_term_to_binary_short_integer
{
    is("\x83a\0", Erlang::term_to_binary(0));
    is("\x83a\xff", Erlang::term_to_binary(255));
}
# EncodeTestCase, test_term_to_binary_integer
{
    is("\x83b\xff\xff\xff\xff", Erlang::term_to_binary(-1));
    is("\x83b\x80\0\0\0", Erlang::term_to_binary(-2147483648));
    is("\x83b\0\0\1\0", Erlang::term_to_binary(256));
    is("\x83b\x7f\xff\xff\xff", Erlang::term_to_binary(2147483647));
}
# EncodeTestCase, test_term_to_binary_long_integer
{
    is("\x83n\4\0\0\0\0\x80", Erlang::term_to_binary(2147483648));
    is("\x83n\4\1\1\0\0\x80", Erlang::term_to_binary(-2147483649));
}
# EncodeTestCase, test_term_to_binary_float
{
    # due to perl, 0.0 must be quoted as a string,
    # otherwise perl makes it an integer
    is("\x83F\0\0\0\0\0\0\0\0", Erlang::term_to_binary('0.0'));
    is("\x83F?\xe0\0\0\0\0\0\0", Erlang::term_to_binary(0.5));
    is("\x83F\xbf\xe0\0\0\0\0\0\0", Erlang::term_to_binary(-0.5));
    is("\x83F@\t!\xfbM\x12\xd8J", Erlang::term_to_binary(3.1415926));
    is("\x83F\xc0\t!\xfbM\x12\xd8J", Erlang::term_to_binary(-3.1415926));
}
# EncodeTestCase, test_term_to_compressed_term
{
    my @lst = (Erlang::OtpErlangList->new([])) x 15;
    is("\x83P\x00\x00\x00\x15x\x9c\xcba``\xe0\xcfB\x03\x00B@\x07\x1c",
       Erlang::term_to_binary(Erlang::OtpErlangList->new(\@lst), 'true'));
    is("\x83P\x00\x00\x00\x15x\x9c\xcba``\xe0\xcfB\x03\x00B@\x07\x1c",
       Erlang::term_to_binary(Erlang::OtpErlangList->new(\@lst), 6));
    is("\x83P\x00\x00\x00\x15x\xda\xcba``\xe0\xcfB\x03\x00B@\x07\x1c",
       Erlang::term_to_binary(Erlang::OtpErlangList->new(\@lst), 9));
    is("\x83P\x00\x00\x00\x15x\x01\x01\x15\x00\xea\xffl\x00\x00\x00" .
       "\x0fjjjjjjjjjjjjjjjjB@\x07\x1c",
       Erlang::term_to_binary(Erlang::OtpErlangList->new(\@lst), 0));
    is("\x83P\0\0\0\x17\x78\xda\xcb\x66\x10\x49\xc1\2\0\x5d\x60\x08\x50",
       Erlang::term_to_binary('d' x 20, 9));
}


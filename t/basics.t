#!/usr/bin/env perl

use strict;
use warnings qw(all);

use FindBin ();
use lib "$FindBin::Bin/../lib/";

use Test::Most tests => 9;

use_ok 'MooseX::Role::Hashable';

{
	package Foo;
	use Moose;
	with 'MooseX::Role::Hashable';

	has public => (is => 'rw');
	has _private => (is => 'ro');
	has bare => (is => 'bare');
	has empty => (is => 'rw');
	has lazy => (is => 'rw', lazy => 1, builder => '_build_laissez');
	has lazy_build => (is => 'rw', lazy_build => 1);
	has reference => (is => 'rw');

	sub _build_laissez { 'laissez' }
	sub _build_lazy_build { 'lazier' }

	__PACKAGE__->meta->make_immutable;
}

my @ref_val = qw{mom and dad};
my $foo = Foo->new(public => 'beach', _private => 'property', bare => 'ly tall enough', reference => \@ref_val);

is $foo->as_hash->{public}, 'beach', 'Public attributes appear';
is $foo->as_hash->{_private}, 'property', 'Private attributes appear';
is $foo->as_hash->{bare}, 'ly tall enough', 'Bare attributes appear';
is $foo->as_hash->{empty}, undef, 'Uninitialized attributes appear';
is $foo->as_hash->{lazy}, 'laissez', 'Lazy attributes appear';
is $foo->as_hash->{lazy_build}, 'lazier', 'Lazy-built attributes appear';
is $foo->as_hash->{reference}, \@ref_val, 'Reference attributes are shallowly copied';
is_deeply
	$foo->as_hash,
	{public => 'beach', _private => 'property', empty => undef, bare => 'ly tall enough', lazy => 'laissez', lazy_build => 'lazier', reference => \@ref_val},
	'All attributes are accounted for';

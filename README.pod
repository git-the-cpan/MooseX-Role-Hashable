package MooseX::Role::Hashable;

=head1 NAME

MooseX::Role::Hashable - transform the object into a hash

=cut

use strict;
use warnings;

use Moose::Role;
use namespace::autoclean;

=head1 VERSION

Version 1.02

=cut

our $VERSION = '1.02';

=head1 SYNOPSIS

This module adds a single method to an object to convert it into a simple hash.
In some ways, this can be seen as the inverse function to I<new>, provided
nothing too crazy is going on during initialization.

Example usage:

	package Foo;
	use Moose;
	use MooseX::Role::Hashable;

	has field1 => (is => 'rw');
	has field2 => (is => 'ro');
	has field3 => (is => 'bare');

	__PACKAGE__->meta->make_immutable;

	package main;

	my $foo = Foo->new(field1 => 'val1', field2 => 'val2', field3 => 'val3');
	$foo->as_hash;
	# => {field1 => 'val1', field2 => 'val2', field3 => 'val3'}

=cut

do {
	my $moose_meta = Moose::Meta::Class->meta;
	my $modify_immutable = $moose_meta->is_immutable;

	$moose_meta->make_mutable if $modify_immutable;

	$moose_meta->add_after_method_modifier('make_immutable', sub {
		my $meta = shift;
		my $class = $meta->name;
		$class->optimize_as_hash
			if $class->can('does')
			&& $class->does(__PACKAGE__);
	});

	$moose_meta->add_after_method_modifier('make_mutable', sub {
		my $meta = shift;
		my $class = $meta->name;
		$class->deoptimize_as_hash
			if $class->can('does')
			&& $class->does(__PACKAGE__);
	});

	$moose_meta->make_immutable if $modify_immutable;
};

=head1 METHODS

=cut

=head2 as_hash

Transform the object into a hash of attribute-value pairs.  All attributes,
including those without a reader, are extracted.  If a value is a reference,
as_hash will perform a shallow copy.

=cut

my %CLASS_TO_POSSIBLE_ATTRIBUTES;

sub as_hash {
	my $self = shift;

	my @possible_attributes = exists $CLASS_TO_POSSIBLE_ATTRIBUTES{ref $self}
		? @{$CLASS_TO_POSSIBLE_ATTRIBUTES{ref $self}}
		: $self->meta->get_all_attributes;

	my %copy = %$self;
	my @missing_attributes = grep { ! exists $copy{$_->name} } @possible_attributes;
	$copy{$_->name} = $_->get_value($self) for @missing_attributes;

	return \%copy;
}

sub optimize_as_hash {
	my $class = shift;

	@{$CLASS_TO_POSSIBLE_ATTRIBUTES{$class}} = grep {
		! ($_->is_required || ! $_->is_lazy && ($_->has_builder || $_->has_default))
	} $class->meta->get_all_attributes;

	for ($class->meta->direct_subclasses) {
		if ($class->meta->is_immutable) {
			$_->meta->make_mutable;
			$_->meta->make_immutable;
		} else {
			$_->optimize_as_hash;
		}
	}

	return;
}

sub deoptimize_as_hash {
	my $class = shift;

	delete $CLASS_TO_POSSIBLE_ATTRIBUTES{$class};
	$_->deoptimize_as_hash for $class->meta->direct_subclasses;

	return;
}

=head1 AUTHOR

Aaron Cohen, C<< <aarondcohen at gmail.com> >>

Special thanks to:
L<Dibin Pookombil|https://github.com/dibinp>

=head1 ACKNOWLEDGEMENTS

This module was made possible by L<Shutterstock|http://www.shutterstock.com/>
(L<@ShutterTech|https://twitter.com/ShutterTech>).  Additional open source
projects from Shutterstock can be found at
L<code.shutterstock.com|http://code.shutterstock.com/>.

=head1 BUGS

Please report any bugs or feature requests to C<bug-MooseX-Role-Hashable at rt.cpan.org>, or through
the web interface at L<https://github.com/aarondcohen/perl-moosex-role-hashable/issues>.  I will
be notified, and then you'll automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc MooseX::Role::Hashable

You can also look for information at:

=over 4

=item * Official GitHub Repo

L<https://github.com/aarondcohen/perl-moosex-role-hashable>

=item * GitHub's Issue Tracker (report bugs here)

L<https://github.com/aarondcohen/perl-moosex-role-hashable/issues>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/MooseX-Role-Hashable>

=item * Official CPAN Page

L<http://search.cpan.org/dist/MooseX-Role-Hashable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013,2014 Aaron Cohen.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of MooseX::Role::Hashable

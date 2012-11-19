package MusicBrainz::Server::Entity::Tracklist;
use Moose;

use MusicBrainz::Server::Entity::Types;

extends 'MusicBrainz::Server::Entity';
with 'MusicBrainz::Server::Entity::Role::Editable';

has 'track_count' => (
    is => 'rw',
    isa => 'Int'
);

has 'tracks' => (
    is => 'rw',
    isa => 'ArrayRef[Track]',
    lazy => 1,
    default => sub { [] },
    traits => [ 'Array' ],
    handles => {
        all_tracks => 'elements',
        add_track => 'push',
        clear_tracks => 'clear'
    }
);

# XXX this is a hack, but useful :(
has 'medium' => (
    is => 'rw',
    isa => 'Medium'
);

=head2 length

Return the duration of the tracklist in microseconds.
(or undef if the duration of one or more tracks is not known).

=cut

sub length {
    my $self = shift;

    my $length = 0;

    for my $trk ($self->all_tracks)
    {
        return undef unless defined $trk->length;

        $length += $trk->length;
    }

    return $length;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2009 Lukas Lalinsky

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

=cut

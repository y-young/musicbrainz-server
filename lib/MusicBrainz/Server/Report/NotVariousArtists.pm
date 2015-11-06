package MusicBrainz::Server::Report::NotVariousArtists;
use Moose;
use MusicBrainz::Server::Constants qw( $VARTIST_ID );

with 'MusicBrainz::Server::Report::RecordingReport',
     'MusicBrainz::Server::Report::FilterForEditor::RecordingID';

sub query {
    "
        SELECT
            r.id AS recording_id,
            row_number() OVER (ORDER BY r.artist_credit, r.name)
        FROM recording r
        JOIN artist_credit ac on ac.id = r.artist_credit
        JOIN artist_credit_name acn on acn.artist_credit = r.artist_credit
        WHERE acn.artist = $VARTIST_ID AND ac.name != 'Various Artists'
    ";
}

sub template
{
    return 'report/not_various_artists.tt';
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 COPYRIGHT

Copyright (C) 2015 MetaBrainz Foundation

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

#!/usr/bin/perl -w
#____________________________________________________________________________
#
#   CD Index - The Internet CD Index
#
#   Copyright (C) 1998 Robert Kaye
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
#   $Id$
#____________________________________________________________________________
                                                                               
use CGI;
use DBI;
use DBDefs; 
use strict;
use MusicBrainz;

my ($o, $cd, $search); 
my ($dbh, $sth, $sql); 

$cd = new MusicBrainz;
$o = $cd->GetCGI;

$cd->Header('Track Search Results');
  
$search = $o->param('track');
if (!defined $search)
{
print <<END;

	 <FONT SIZE=+1 COLOR=RED>
	 Note:
	 </FONT>
   Please enter some text into the search field. Click on the
   Back button in your browser and try again.
	 <p>
   </td></tr></table>
END
   print $o->end_html;
   exit;
}

$dbh = DBI->connect(DBDefs->DSN,DBDefs->DB_USER,DBDefs->DB_PASSWD);
if (!$dbh)
{
    print "<font size=+1 color=red>Sorry, the database is currently ";
    print "not available. Please try again in a few minutes.</font>";
    print "(Error: ".$DBI::errstr.")";
}
else
{
    my @row;

    $sql = $cd->AppendWhereClause($search, 
             "select Track.id, Track.Name, Album.id, Album.name, " .
             "Artist.id, Artist.name from Track, Album, Artist where " .
             "Track.artist = Artist.id and Track.album = Album.id and ",
             "Track.Name") .
             " order by Track.name";

    $sth = $dbh->prepare($sql);
    $sth->execute();
    if ($sth->rows > 0)
    {
        print"Click on the artist name to see all the albums for that artist.";
        print" Click on the album name to see the album details";
        print", or click on one of the 'Edit' links to edit the name of the ";
        print"appropriate item:<p><table><tr><td><b>Track Name:</b></td>\n";
        print"<td><b>Album:</b></td>\n";
        print"<td><b>Artist:</b></td>\n";
        print"<td><b>Options:</b></td></tr>\n";
        while(@row = $sth->fetchrow_array)
        {
           print"<tr><td>",$o->escapeHTML($row[1]),"</td>\n";
           print"<td><a href=\"hget.pl?albumid=$row[2]\">", $o->escapeHTML($row[3]);
           print"</a></td>\n<td><a href=\"showartist.pl?artistid=$row[4]\">";
           print $o->escapeHTML($row[5]);
           print"</a></td><td>\n";
           print"<a href=\"edittrack.pl?trackid=$row[0]\">Edit Track</a>\n";
           print"<a href=\"editalbum.pl?albumid=$row[2]\">Edit Album</a>\n";
           print"<a href=\"editartist.pl?artistid=$row[4]\">Edit Artist</a>\n";
           print"</td></tr>\n";
        }
        print"</table>\n";

    }
    else
    {
        print("There were no items found. Please try again:<p>");

        print $cd->SearchForm();
    }
    $sth->finish;
    $dbh->disconnect;
}

print '	</TD>',"\n";
print '</TR>',"\n";
print '</TABLE>',"\n";

print $o->end_html;

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

my $o; 
my $num_tracks;
my $i;
my ($sth, $sql, $cd, $dbh); 
my ($search, $toc, $id, $tracks);

$o = new CGI;
$cd = new MusicBrainz;
$cd->Header('Submit CD: CD Search Results');

$search = $o->param('search');
$toc = $o->param('toc');
$id = $o->param('id');
$tracks = $o->param('tracks');

$cd->CheckArgs('toc', 'id', 'tracks');
if (!defined $search || $search eq '')
{
print <<END;

	 <FONT COLOR=RED>
	 Note:
	 </FONT>
   Please enter a CD name into the search field. Click on the
   Back button in your browser and try again.
	 <p>
   </td></tr></table>
END
   print $o->end_html;
   exit;
}

my (@row, @ids, %labels);
my (%unused, $first, $found);

$first = 1;
$found = 0;

$cd->Login;
$dbh = $cd->{DBH};

$sql = $cd->AppendWhereClause($search, "select id, name from Album where Artist = 0 and ", "name") . " order by name";
$sth = $dbh->prepare($sql);
$sth->execute();
if ($sth->rows > 0)
{
    my @row;
    my $i;

    for(;@row = $sth->fetchrow_array;) 
    {
        my ($sth2, @row2);
        $sth2 = $dbh->prepare("select Track.id, Track.name, Sequence, Artist.name from Track, Artist where Album = $row[0] and Track.Artist = Artist.id order by Sequence ");
        $sth2->execute();
        if ($sth2->rows == $tracks)
        {
            if ($first)
            {
               $first = 0;
               $found = 1;
               print("Please examine the CDs listed below. If one of ");
               print("the track listings matches the CD that you are ");
               print("submitting, click on <b>Select CD</b> next to ");
               print("the matching album. If none of the listed CD ");
               print("match, click on <b>CD not listed</b>:<br>");
            }

            print $o->start_form(-action=>'found.pl');
            print "<table width=100%><tr><td><b>",$o->escapeHTML($row[1]);
            print "<b></td><td align=right>";
            print $o->p,$o->submit('Select CD>>');
            print "</td></tr></table>";

            print "<p><table><tr><td></td><td>Track No:</td>";
            print "<td>Track Title</td><td>Artist:</td></tr>\n";

            while(@row2 = $sth2->fetchrow_array)
            {
                print "<tr><td>&nbsp;&nbsp;</td><td align=center>";
                print $row2[2]+1;
                print "</td><td>",$o->escapeHTML($row2[1]),"</td>\n";
                print "<td>",$o->escapeHTML($row2[3]),"</td></tr>\n";
            }
            print '</table><p>';

            print $o->hidden(-name=>'id',-default=>'$id');
            print $o->hidden(-name=>'album',-default=>"$row[0]");
            print $o->hidden(-name=>'toc',-default=>$o->param('toc'));
            print $o->end_form;
        }
        else
        {
            $unused{"$row[1]"}=$sth2->rows;
        }
        $sth2->finish();

    }

    if (scalar(%unused) > 0)
    {
        print("The following CDs in the CD Index are not applicable ");
        print("because they have a different number of tracks than ");
        print("than the CD you are submitting:<p>");
        foreach $i (keys(%unused))
        {
            print "CD <b>",$o->escapeHTML($i);
            print "</b> has " . $unused{"$i"} . " tracks.<br>";
        }
        print("<p>Even though there may be a CD listed with the same ");
        print("name as you are submitting, there sometimes are different ");
        print("editions of the same CD that have a different number ");
        print("of tracks.");
    }

    print("<p>If the CD is not listed above ");
    print("you may either try the search again, ");
    print("or click on 'New CD' to enter the information for this ");
    print("CD. Please make sure to search carefully before you go ");
    print("through the effort to add a new CD.");
}
else
{
    print("There were no CDs found given the keywords ");
    print("<b>'$search'</b>. You may either try again, ");
    print("or click on 'New CD' to enter the information for this ");
    print("CD. Please make sure to search carefully before you go ");
    print("through the effort to add a new CD.");
}

print $o->start_form(-action=>'menter.pl');
print $o->hidden(-name=>'id',-default=>'$id');
print $o->hidden(-name=>'toc',-default=>$toc);
print $o->hidden(-name=>'tracks',-default=>'$tracks');
print $o->p,$o->submit('New CD>>');
print $o->end_form;

print("<hr><b>Start another CD search:</b><p>\n");

print $o->start_form(-action=>'malbum.pl');
print "CD Name:<br>\n";
print $o->textfield(-name=>'search',size=>'30');
print $o->hidden(-name=>'id',-default=>'$id');
print $o->hidden(-name=>'toc',-default=>$toc);
print $o->hidden(-name=>'tracks',-default=>'$tracks');
print $o->p,$o->submit('Search');
print $o->end_form;

$sth->finish;

$cd->Logout;
$cd->Footer; 

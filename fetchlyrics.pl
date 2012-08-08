#!/usr/bin/perl

die("OBSOLETE -- use $HOME/wrk/XpLOOsion/muziek/common/fetchlyrics.pl instead.\n");
use strict;
use warnings;
use HTML::Entities;
binmode( STDOUT, ':encoding(utf-8)' );
my $pp;
my $lp = -1;
while ( <> ) {
    $pp = 0, $lp = -1, print("\n"), next if /^\s*<(staff|bar)\b/i;
    print("\n---\n"), next if /^\s*<\/staff\b/i;

    # 	<LyricItem position="512" voicenumber="1" dx="0" dy="-192" hidden="false" Duration="128" Text="noot," StyleId="text.staff.space.hypen.lyrics.verse1" StyleAsText="Lyrics line 1" SyllableType="1" NumNotes="1" ></LyricItem>
    next unless /<lyricitem\b.*\sposition="(\d+)".*\stext="(.*?)"/i;
    my $t = $2;
    next if length($t) == 0;
    my $pos = $1;
    if ( $pos == $lp ) {
	next;
    }
    if ( $pp && $pos < $pp ) {
	print "\n";
    }
    $lp = $pp = $pos;

    # The text is encoded, but it is encoded again for the XML dump.
    $t = decode_entities($t) if $t =~ /\&/;
    $t =~ s/\&apos;/&rsquo;/g;
    $t = decode_entities($t) if $t =~ /\&/;
#    $t =~ s/_+$//;
    my $hyphen;
    $t = $1, $hyphen = 1 if $t =~ /^(.*)-$/;
    $t = '"' . $t . '"' unless $t =~ /^[[:alpha:]]\S*$/;
    print $t, " ";
    print "-- " if $hyphen;
}

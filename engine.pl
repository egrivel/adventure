#!/usr/local/bin/perl -w

use strict;
use JSON;

require("adv-data.pm");
require("adv-process.pm");

read_data("grayson.json");
process();

# -----------------------------------------------------------------------------
# Common function available throughout
# -----------------------------------------------------------------------------

sub out {
  my $msg = $_[0];

  # Handle textual output
  $msg =~ s/&rsquo;/\'/g;
  $msg =~ s/&nbsp;/ /g;
  $msg =~ s/<br\/>/\n/g;
  $msg =~ s/<\/?strong>//g;
  
  my @msg = split(/\n/, $msg);
  my $i = 0;
  for ($i = 0; defined($msg[$i]); $i++) {
    while (length($msg[$i]) > 60) {
      if ($msg[$i] =~ s/^(.{20,70})\s+//) {
        print " > $1\n";
      } else {
        last;
      }
    }
    print " > " . $msg[$i] . "\n";
  }

  print "\n";
}

sub error {
  my $msg = $_[0];

  die "$msg\n";
}


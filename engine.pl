#!/usr/local/bin/perl -w

use strict;
use JSON;

require("adv-data.pm");
require("adv-process.pm");

read_data("grayson.jsonc");
process();

# -----------------------------------------------------------------------------
# Common function available throughout
# -----------------------------------------------------------------------------

sub out {
  my $msg = $_[0];
  my $extra_line = $_[1];
  if (!defined($extra_line)) {
    $extra_line = 1;
  }

  # Handle textual output
  $msg =~ s/&rsquo;/\'/g;
  $msg =~ s/&ldquo;/\"/g;
  $msg =~ s/&rdquo;/\"/g;
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

  print "\n" if ($extra_line);
}

sub error {
  my $msg = $_[0];

  die "$msg\n";
}


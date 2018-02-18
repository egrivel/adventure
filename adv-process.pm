# 
# Processing the input
#
# This file has the global input loop at the bottom, and all the functions
# that process different commands.
#

#
# Global environment
#
sub match_name {
  my $item = $_[0];
  my $name = $_[1];

  if (defined($$item{"name"}) && $$item{"name"} eq $name) {
    return 1;
  }
  if (defined($$item{"alias"})) {
    my $i;
    for ($i = 0; defined($$item{"alias"}[$i]); $i++) {
      if ($$item{"alias"}[$i] eq $name) {
        return 1;
      }
    }
  }
  return 0;
}

sub describe_location {
  my $loc = $_[0];

  my $out = $$loc{"descr"};

  my $i;
  my $list = "";
  for ($i = 0; defined($$loc{"items"}[$i]); $i++) {
    my $item = $$loc{"items"}[$i];
    if (is_portable($item)) {
      if ($list ne "") {
        $list .= ", ";
      }
      $list .= "a " . $$item{"name"};
    }
  }
  if ($list ne "") {
    $list =~ s/,([^,]+)$/ and$1/;
    $out .= "\nYou can see $list.";
  }
  out($out);
}

sub process_look {
  my $noun = $_[0];
  my $loc = get_location();

  if ($noun eq "") {
    describe_location($loc);
  } else {
    out(get_item_descr($$loc{"id"}, $noun));
  }
}

sub do_action {
  my $loc = $_[0];
  if (defined($$loc{"action"})) {
    eval($$loc{"action"});
  }
}

sub process_go {
  my $direction = $_[0];
  my $loc = get_location();

  my $i;
  for ($i = 0; defined($$loc{"exits"}[$i]); $i++) {
    if (match_name($$loc{"exits"}[$i], $direction)) {
      process_action("leave", "");
      set_location($$loc{"exits"}[$i]{"location"});
      process_action("enter", "");
      # do_action(get_location());
      describe_location(get_location());
      return;
    }
  }

  out ("I don&rsquo;t know where $direction is.");
}

sub is_portable {
  my $item = $_[0];

  if (!defined($$item{"type"})) {
    return 0;
  }
  return ($$item{"type"} eq "portable");
}

sub process_get {
  my $noun = $_[0];
  my $loc = get_location();

  my $i;
  for ($i = 0; defined($$loc{"items"}[$i]); $i++) {
    my $item = $$loc{"items"}[$i];
    if (match_name($item, $noun)) {
      if (is_portable($item)) {
        add_inventory($item);
        splice($$loc{"items"}, $i, 1);
        out($$item{"name"} . " has been added to your inventory.");
      } else {
        out("You can&rsquo;t take " . $$item{"name"});
      }
      return;
    }
  }

  out("I don&rsquo;t see any $noun");
}

sub process_drop {
  my $noun = $_[0];
  my $loc = get_location();

  my $nr = get_nr_inventory();
  my $i;
  for ($i = 0; $i < $nr; $i++) {
    my $item = get_inventory($i);
    if ($$item{"name"} eq $noun) {
      drop_inventory($i);
      if (!defined($$loc{"items"})) {
        $$loc{"items"} = ();
        $$loc{"items"}[0] = $item;
      } else {
        my $j;
        for ($j = 0; defined($$loc{"items"}[$j]); $j++) {
          # nothing
        }
        $$loc{"items"}[$j] = $item;
      }
      describe_location($loc);
      return;
    }
  }
  out("You are not carrying $noun.");
}

sub process_inventory {
  my $noun = $_[0];

  my $nr = get_nr_inventory();
  my $i;
  my $list = "";
  for ($i = 0; $i < $nr; $i++) {
    my $item = get_inventory($i);
    if ($list ne "") {
      $list .= " ";
    }
    $list .= $$item{"name"};
  }
  if ($list eq "") {
    out("Your are not carrying anything.");
  } else {
    out("You are carrying: $list");
  }
}

# Display the current time
sub process_time {
  my $sec = get_time() + (8 * 60 * 60);

  my $min = int($sec / 60);
  $sec -= 60 * $min;
  $sec = '0' . $sec if ($sec < 10);

  my $hr = int($min / 60);
  $min -= 60 * $hr;
  $min = '0' . $min if ($min < 10);

  out("$hr:$min:$sec GST");
}

sub process_action {
  my $verb = $_[0];
  my $noun = $_[1];

  my $loc = get_location();
  if (defined($$loc{"actions"})) {
    if (defined($$loc{"actions"}{$verb})) {
      my $cmd = "my \$noun = '$noun'; " . $$loc{"actions"}{$verb};
      eval $cmd;
      return $1;
    }
  }

  my $item = find_item($noun);
  if (defined($item)) {
    if (defined($$item{"actions"}{$verb})) {
      my $cmd = "my \$noun = '$noun'; " . $$item{"actions"}{$verb};
      eval $cmd;
      return $1;
    }
  }

  return 0;
}

sub process_command {
  my $verb = $_[0];
  my $noun = $_[1];

  if ($verb eq "l" || $verb eq "look") {
    process_look($noun);
  } elsif ($verb eq "g" || $verb eq "go") {
    process_go($noun);
  } elsif ($verb eq "e" || $verb eq "east") {
    process_go("east");
  } elsif ($verb eq "w" || $verb eq "west") {
    process_go("west");
  } elsif ($verb eq "n" || $verb eq "north") {
    process_go("north");
  } elsif ($verb eq "s" || $verb eq "south") {
    process_go("south");
  } elsif ($verb eq "get" || $verb eq "take") {
    process_get($noun);
  } elsif ($verb eq "drop") {
    process_drop($noun);
  } elsif ($verb eq "i" || $verb eq "inventory") {
    process_inventory($noun);
  } elsif ($verb eq "time") {
    process_time($noun);
  } elsif ($verb eq "wait") {
    my $time = get_time();
    $time += 60 * $noun;
    set_time($time);
  } elsif (process_action($verb, $noun)) {
    # already processed
  } else {
    out("Sorry, I don't understand $verb");
  }
}

sub display_splash {
  open(FILE, "<splash.txt") || return;
  my $data = "";
  while (<FILE>) {
    chomp();
    s/\r//;
    $data .= $_ . "\n";
  }
  close FILE;

  $data =~ s/\n\n/<br\/><br\/>/g;
  $data =~ s/\n/ /g;
  out($data);
}

sub process {
  display_splash();

  my $loc = get_location();
  describe_location($loc);

  set_time(0);

  while (<>) {
    chomp();
    s/\r//;
    if (/^\s*quit\s*$/i) {
      out("Goodbye!");
      return;
    } elsif (/^\s*(\w+)\s*$/) {
      process_command(lc($1), "");
    } elsif (/^\s*(\w+)\s+(.*?)\s*$/) {
      process_command(lc($1), $2);
    } elsif (/\S/) {
      out("Sorry, could you rephrase that?")
    }

    # A clock tick of about 5 minutes
    process_action("tick", "");
    my $time = get_time();
    $time += 260 + int(rand(80));
    set_time($time);
  }
}

return 1;
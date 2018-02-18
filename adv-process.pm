# 
# Processing the input
#
# This file has the global input loop at the bottom, and all the functions
# that process different commands.
#

# Match against the ID, name or alias. The item can be anything that can
# have and ID, name and/or alias attribute.
sub match_name {
  my $item = $_[0];
  my $name = $_[1];

  if (defined($$item{"id"}) && $$item{"id"} eq $name) {
    return 1;
  }

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

# Describe a location. This gives both the location's description and all
# the objects that are in that location.
sub describe_location {
  my $loc_id = $_[0];

  my $loc = get_location($loc_id);
  my $out = $$loc{"descr"};
  my $list = list_objects_in_location($loc_id);

  if ($list ne "") {
    $out .= "\nYou can see $list.";
  }
  out($out);
}

sub process_look {
  my $noun = $_[0];
  my $loc_id = get_current_location_id();

  if ($noun eq "") {
    describe_location($loc_id);
    return;
  }

  my $item = get_item($noun);
  if (defined($item)) {
    out(get_item_descr($loc_id, $noun));
    return;
  }

  my $obj = get_object($noun);
  if (defined($obj)) {
    out(get_object_descr($noun));
    return;
  }

  out("I don&rsquo;t know about $noun.");
}

sub do_action {
  my $loc = get_location($_[0]);
  if (defined($$loc{"action"})) {
    eval($$loc{"action"});
  }
}

sub process_go {
  my $direction = $_[0];
  my $loc = get_location(get_current_location_id());

  my $i;
  for ($i = 0; defined($$loc{"exits"}[$i]); $i++) {
    if (match_name($$loc{"exits"}[$i], $direction)) {
      process_action("leave", "");
      set_current_location_id($$loc{"exits"}[$i]{"location"});
      process_action("enter", "");
      # do_action(get_current_location_id());
      describe_location(get_current_location_id());
      return;
    }
  }

  out ("I don&rsquo;t know where $direction is.");
}

sub process_get {
  my $noun = $_[0];

  my $obj = get_object($noun);
  if (defined($obj)) {
    if (get_object_location($noun) eq $INVENTORY) {
      out("You are already carrying $noun.");
    } else {
      # Got an object but not in inventory, so it must be in the current
      # location
      move_object($noun, $INVENTORY);
      out("$noun has been added to your inventory.");
    }
  } else {
    out("I don&rsquo;t see any $noun.");
  }
}

sub process_drop {
  my $noun = $_[0];

  my $obj = get_object($noun);
  if (!defined($obj) || get_object_location($noun) ne $INVENTORY) {
    # the object is not part of the inventory, so you can't drop it
    out("You are not carrying $noun.");
    return;
  }

  my $loc_id = get_current_location_id();
  # move the object from the inventory to the current location
  move_object($noun, $loc_id);
  # show the current location description, which now should include the
  # dropped object
  describe_location($loc_id);
}

sub process_inventory {
  my $object_list = get_object_list();
  my $list = "";
  
  my $i;
  for ($i = 0; defined($$object_list[$i]); $i++) {
    my $id = $$object_list[$i];
    if (get_object_location($id) eq $INVENTORY) {
      if ($list ne "") {
        $list .= " ";
      }
      $list .= $id;
    }
  }

  if ($list eq "") {
    out("Your are not carrying anything.");
  } else {
    out("You are carrying: $list.");
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

  my $loc = get_current_location();
  if (defined($$loc{"actions"})) {
    if (defined($$loc{"actions"}{$verb})) {
      my $cmd = "my \$noun = '$noun'; " . $$loc{"actions"}{$verb};
      eval $cmd;
      return $1;
    }
  }

  my $item = get_item($noun);
  if (defined($item)) {
    if (defined($$item{"actions"}{$verb})) {
      my $cmd = "my \$noun = '$noun'; " . $$item{"actions"}{$verb};
      eval $cmd;
      return 1;
    }
  }

  my $item = get_object($noun);
  if (defined($object)) {
    if (defined($$object{"actions"}{$verb})) {
      my $cmd = "my \$noun = '$noun'; " . $$object{"actions"}{$verb};
      eval $cmd;
      return 1;
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
  # display_splash();

  describe_location(get_current_location_id());

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
my $gl_data = "";
my @gl_inventory;

sub read_data {
  my $fname = $_[0];

  open(FILE, "<$fname") || error("Cannot read data file '$fname'");

  my $data = "";
  while (<FILE>) {
    chomp();
    s/\r//;
    s/\/\/.*$//;
    s/^\s+//;;
    s/\s+$//;
    $data .= $_;
  }
  close FILE;

  $gl_data = decode_json($data);

  $default_location = $$gl_data{"default-location"};
  $gl_location = find_location($default_location);
}

sub find_location {
  my $id = $_[0];
  for ($i = 0; defined($$gl_data{"locations"}[$i]); $i++) {
    if ($$gl_data{"locations"}[$i]{"id"} eq $id) {
      return $$gl_data{"locations"}[$i];
    }
  }
  return undef;
}

sub get_location {
   return $gl_location;
}

sub set_location {
  my $id = $_[0];

  if (defined($id)) {
    my $loc = find_location($id);
    if (defined($loc)) {
      $gl_location = $loc;
    }
  }
}

sub add_inventory {
  my $item = $_[0];

  my $length = @gl_inventory;
  $gl_inventory[$length] = $item;
}

sub drop_inventory {
  my $nr = $_[0];
  splice(@gl_inventory, $nr, 1);
}

sub get_nr_inventory {
  return scalar @gl_inventory;
}

sub get_inventory {
  my $nr = $_[0];
  return $gl_inventory[$nr];
}

sub find_item {
  my $item_name = $_[0];

  my $i;
  my $item;
  for ($i = 0; defined($gl_inventory[$i]); $i++) {
    $item = $gl_inventory[$i];
    if ($$item{"name"} eq $item_name) {
      return $item;
    }
  }

  if (defined($gl_location)) {
    for ($i = 0; defined($$gl_location{"items"}[$i]); $i++) {
      $item = $$gl_location{"items"}[$i];
      if ($$item{"name"} eq $item_name) {
        return $item;
      }
    }
  }
  return undef;
}

sub get_item_descr {
  my $loc_id = $_[0];
  my $item_name = $_[1];

  my $item = find_item($item_name);
  if (defined($item)) {
    if (defined($$item{"get-descr"})) {
      my $value = eval($$item{"get-descr"});
      return $value;
    }
    return $$item{"descr"};
  }  

  return "I don&rsquo;t know about $item_name";
}

sub move_item {
  my $item_name = $_[0];
  my $from_loc = $_[1];
  my $to_loc = $_[2];

  my $from = find_location($from_loc);
  my $to = find_location($to_loc);
  if (!defined($from) || !defined($to)) {
    print "Cannot find $from_loc or $to_loc\n";
    return;
  }

  if (defined($$from{"items"})) {
    my $i;
    for ($i = 0; defined($$from{"items"}[$i]); $i++) {
      my $item = $$from{"items"}[$i];
      if ($$item{"name"} eq $item_name) {
        splice($$from{"items"}, $i, 1);
        if (!defined($$to{"items"})) {
          $$to{"items"} = [];
          $$to{"items"}[0] = $item;
        } else {
          push($$to{"items"}, $item);
        }
        return;
      }
    }
  }
}

return 1;
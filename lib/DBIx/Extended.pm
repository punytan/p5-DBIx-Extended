package DBIx::Extended;
use sane;
use parent 'DBI';
our $VERSION = '0.01';

package DBIx::Extended::db;
use sane;
our @ISA = qw(DBI::db);

sub connected {
    my ($dbh, $dsn, undef, undef, $attr) = @_;

    # should be configurable?
    $dbh->{RaiseError} = 1;
    $dbh->{PrintError} = 0;
    $dbh->{ShowErrorStatement}  = 1;
    $dbh->{AutoInactiveDestroy} = 1;

    my $driver = $dbh->{private_extended_driver} || do {
        $dbh->{private_extended_driver} = (DBI->parse_dsn($dsn))[1];
    };

    if ($driver eq 'mysql' && (not exists $attr->{mysql_enable_utf8})) {
        $dbh->{mysql_enable_utf8} = 1;
        $dbh->do("SET NAMES utf8");
    } elsif ($driver eq 'SQLite' && (not exists $attr->{sqlite_unicode})) {
        $dbh->{sqlite_unicode} = 1;
    }

    $dbh->{private_extended_builder} ||= sub {
        require SQL::Abstract;
        SQL::Abstract->new;
    }->();

    $dbh->SUPER::connected(@_);
}

sub do {
    $_[0]->{private_extended_before_do}
        ? $_[0]->SUPER::do($_[0]->{private_extended_before_do}->(@_))
        : shift->SUPER::do(@_);
}

sub prepare {
    $_[0]->{private_extended_before_prepare}
        ? $_[0]->SUPER::prepare($_[0]->{private_extended_before_prepare}->(@_))
        : shift->SUPER::prepare(@_);
}

sub builder { shift->{private_extended_builder} }
sub query   { shift->prepare(shift)->execute(@_) }
sub insert  { $_[0]->query(shift->{private_extended_builder}->insert(@_)) }
sub update  { $_[0]->query(shift->{private_extended_builder}->update(@_)) }
sub delete  { $_[0]->query(shift->{private_extended_builder}->delete(@_)) }

sub select {
    my $self = shift;
    my ($stmt, @bind) = $self->{private_extended_builder}->select(@_);
    $self->selectrow_hashref($stmt, {}, @bind);
}

sub selectall {
    my $self = shift;
    my ($stmt, @bind) = $self->{private_extended_builder}->select(@_);
    $self->selectall_arrayref($stmt, {Slice => {}}, @bind);
}

sub last_insert_id {
    my $self = shift;

    my $driver = $self->{private_extended_driver};
    return $driver eq 'mysql'
        ? $self->{mysql_insertid}
        : $driver eq 'SQLite'
            ? $self->func("last_insert_rowid")
            : $self->SUPER::last_insert_id(@_);
}


package DBIx::Extended::st;
our @ISA = qw(DBI::st);

1;
__END__

=head1 NAME

DBIx::Extended -

=head1 SYNOPSIS

  use DBIx::Extended;

=head1 DESCRIPTION

DBIx::Extended is

=head1 AUTHOR

punytan E<lt>punytan@gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

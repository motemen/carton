package xt::CLI;
use strict;
use base qw(Exporter);
our @EXPORT = qw(run cli);

use Test::Requires qw( Directory::Scratch Capture::Tiny );

sub cli {
    my $dir = Directory::Scratch->new();
    chdir $dir;

    my $app = Carton::CLI::Tested->new(dir => $dir);
    $app->carton->{mirror} = "$ENV{HOME}/minicpan";

    return $app;
}

sub run {
    my $app = cli();
    $app->run(@_);
    return $app;
}

package Carton::CLI::Tested;
use parent qw(Carton::CLI);

use Capture::Tiny qw(capture);

sub new {
    my($class, %args) = @_;

    my $self = $class->SUPER::new;
    $self->{dir} = $args{dir};

    return $self;
}

sub dir {
    my $self = shift;
    $self->{dir};
}

sub print {
    my $self = shift;
    $self->{output} .= $_[0];
}

sub run {
    my($self, @args) = @_;
    $self->{output} = '';
    ($self->{system_output}, $self->{system_error}) = capture {
        eval { $self->SUPER::run(@args) };
    };
}

sub output {
    my $self = shift;
    $self->{output};
}

sub system_output {
    my $self = shift;
    $self->{system_output};
}

sub system_error {
    my $self = shift;
    $self->{system_error};
}

1;


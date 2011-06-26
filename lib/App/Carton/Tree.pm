package App::Carton::TreeNode;
use strict;
use warnings;

my %cache;

sub cached {
    my($class, $key) = @_;
    return $cache{$key};
}

sub new {
    my($class, $key, $pool) = @_;

    my $meta = delete $pool->{$key} || {};

    my $self = bless [ $key, $meta,  [] ], $class;
    $cache{$key} = $self;

    return $self;
}

sub walk_down {
    my($self, $cb) = @_;

    $cb ||= sub {
        my($node, $depth) = @_;
        print " " x $depth;
        print $node->key, "\n";
    };

    $self->_walk_down($cb, undef, 0);
}

sub _walk_down {
    my($self, $pre_cb, $post_cb, $depth) = @_;

    my @child = $self->children;
    for my $child ($self->children) {
        local $App::Carton::Tree::Abort = 0;
        if ($pre_cb) {
            $pre_cb->($child, $depth, $self);
        }

        unless ($App::Carton::Tree::Abort) {
            $child->_walk_down($pre_cb, $post_cb, $depth + 1);
        }

        if ($post_cb) {
            $post_cb->($child, $depth, $self);
        }
    }
}

sub abort {
    $App::Carton::Tree::Abort = 1;
}

sub key      { $_[0]->[0] }
sub metadata { $_[0]->[1] }

sub children { @{$_[0]->[2]} }

sub add_child {
    my $self = shift;
    push @{$self->[2]}, @_;
}

sub remove_child {
    my($self, $rm) = @_;

    my @new;
    for my $child (@{$self->[2]}) {
        push @new, $child if $rm->key ne $child->key;
    }

    $self->[2] = \@new;
}

sub is {
    my($self, $node) = @_;
    $self->key eq $node->key;
}

package App::Carton::Tree;
our @ISA = qw(App::Carton::TreeNode);

sub new {
    bless [0, {}, []], shift;
}

sub finalize {
    my $self = shift;

    my %subtree;
    my @ancestor;

    my $down = sub {
        my($node, $depth, $parent) = @_;

        if (grep $node->is($_), @ancestor) {
            $parent->remove_child($node);
            return $self->abort;
        }

        $subtree{$node->key} = 1 if $depth > 0;

        push @ancestor, $node;
        return 1;
    };

    my $up = sub { pop @ancestor };
    $self->_walk_down($down, $up, 0);

    # remove root nodes that are sub-tree of another
    for my $child ($self->children) {
        if ($subtree{$child->key}) {
            $self->remove_child($child);
        }
    }

    %cache = ();
}

1;
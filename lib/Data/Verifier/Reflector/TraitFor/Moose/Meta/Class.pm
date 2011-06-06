package Data::Verifier::Reflector::TraitFor::Moose::Meta::Class;
use Moose::Role;
use Data::Verifier;

has dv_profile => (
    isa => 'HashRef[HashRef]', is => 'rw',
    traits => [qw(Hash)],
    default => sub { {} },
    handles => {
        dv_add_verifier_column  => 'set',
        dv_attribute_names      => 'keys',
    },
);

has dv_default_filters => (
    isa => 'ArrayRef[Str]', is => 'rw',
    traits => [qw(Array)],
    default => sub { [] },
    handles => {
        dv_add_to_filters => 'push',
    },
);

has verifier => (
    isa => 'Data::Verifier', is => 'ro',
    lazy_build => 1,
    handles => [qw(verify)],
);

sub _build_verifier {
    my $self = shift;
    Data::Verifier->new(
        filters => $self->dv_default_filters,
        profile => $self->dv_profile,
    );
}


1;

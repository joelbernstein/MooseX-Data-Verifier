package MooseX::Data::Verifier;
use strictures;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    class_metaroles => {
        class => [qw(
            Data::Verifier::Reflector::TraitFor::Moose::Meta::Class
        )],
    },
    base_class_roles => [qw(
        MooseX::Data::Verifier::Role
    )],
);

1;

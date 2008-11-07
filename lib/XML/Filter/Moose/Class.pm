package XML::Filter::Moose::Class;
use Moose;
use MooseX::AttributeHelpers;
use Moose::Util::TypeConstraints;
use Template;
extends qw(XML::Filter::Moose);
with qw(XML::Filter::Moose::ClassRegistry);
with qw(XML::Filter::Moose::ClassTemplate);

sub get_class_name {
    my ( $self, $name ) = @_;
    my $namespace =
        $self->parent_element
      ? $self->parent_element->{classname}
      : $self->namespace;
    return $namespace . '::' . ucfirst $name;
}

sub create_class {
    my ( $self, $name, $params ) = @_;
    return Moose::Meta::Class->create( $name => %$params );
}

sub add_attribute {
    my ( $self, $class, $type, $attr ) = @_;
    my $name = $attr->{Name};
    $name = $name . '_collection' if $type eq 'child';
    $attr->{isa} ||= 'Str';
    $attr->{traits} = ['XML::Toolkit::MetaDescription::Trait'];
    unless ( $type eq 'child' ) {
        $attr->{description} = {
            node_type    => $type,
            NamespaceURI => $attr->{NamespaceURI},
            LocalName    => $attr->{LocalName},
            Prefix       => $attr->{Prefix},
            Name         => $attr->{Name},
        };
    }
    $class->add_attribute( $name => $attr )
      unless $class->has_attribute($name);
}

augment 'start_element' => sub {
    my ( $self, $el ) = @_;
    my $classname = $self->get_class_name( $el->{Name} );
    class_type $classname;
    $el->{classname} = $classname;
    if ( $self->is_root ) {
        my $class = $self->create_class( $classname => $el );
        $self->add_class( $classname => $class );
        $self->add_attribute( $class, 'attribute' => $_ )
          for values %{ $el->{Attributes} };
        return;
    }
    my $class = $self->create_class( $classname => $el );
    $self->add_class( $classname => $class );
    $self->add_attribute( $class, 'attribute' => $_ )
      for values %{ $el->{Attributes} };

    my $parent_class = $self->get_class( $self->parent_element->{classname} );
    $self->add_attribute(
        $parent_class,
        'child',
        {
            %$el,
            isa               => "ArrayRef[$classname]",
            should_auto_deref => 1,
            is_lazy           => 1,
            default           => sub { [] },
        }
    );
};

augment 'end_element' => sub {
    my ( $self, $el ) = @_;
    my $top = $self->current_element;
    confess "INVALID PARSE: $el->{Name} ne $top->{Name}"
      unless $el->{Name} eq $top->{Name};

};
no Moose;  # unimport Moose's keywords so they won't accidentally become methods
1;         # Magic true value required at end of module
__END__

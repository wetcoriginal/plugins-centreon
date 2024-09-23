#!/usr/bin/perl
use strict;
use warnings;
use Net::SNMP;
use Getopt::Long;

# Variables pour les arguments en ligne de commande
my $hostname;
my $community;
my $version;

# OID pour sysDescr (description système)
my $sys_descr_oid = '1.3.6.1.2.1.1.1.0';

# Récupérer les arguments via Getopt::Long
GetOptions(
    'h=s' => \$hostname,   # Option -h pour l'adresse IP ou le hostname
    'c=s' => \$community,  # Option -c pour la communauté SNMP
    'v=s' => \$version     # Option -v pour la version SNMP (1, 2c, ou 3)
) or die "Usage: $0 -h <hostname> -c <community> -v <version>\n";

# Vérifier que les options obligatoires sont fournies
if (!defined $hostname || !defined $community || !defined $version) {
    die "Usage: $0 -h <hostname> -c <community> -v <version>\n";
}

# Créer une session SNMP en fonction de la version SNMP
my ($session, $error);

if ($version eq '2c') {
    ($session, $error) = Net::SNMP->session(
        -hostname  => $hostname,
        -community => $community,
        -port      => 161,
        -version   => 'snmpv2c'   # Pour SNMPv2c
    );
} elsif ($version eq '1') {
    ($session, $error) = Net::SNMP->session(
        -hostname  => $hostname,
        -community => $community,
        -port      => 161,
        -version   => 'snmpv1'    # Pour SNMPv1
    );
} else {
    die "Version SNMP non supportée : $version. Utilisez '1' ou '2c'.\n";
}

# Vérifier la création de la session SNMP
if (!defined $session) {
    die "Erreur lors de la création de la session SNMP : $error\n";
}

# Envoyer la requête SNMP pour obtenir la version (sysDescr)
my $result = $session->get_request(-varbindlist => [$sys_descr_oid]);

if (!defined $result) {
    print "Erreur lors de la récupération SNMP : " . $session->error() . "\n";
    $session->close();
    exit 1;
}

# Afficher la version du switch
print "Version du Switch : " . $result->{$sys_descr_oid} . "\n";

# Fermer la session SNMP
$session->close();

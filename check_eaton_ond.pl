#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Net::SNMP;

# OID pour la batterie et les alarmes du Eaton 5PX2200iRT
my %oids = (
    # Batterie
    'battery_status'  => '.1.3.6.1.2.1.33.1.2.1.0',   # Statut de la batterie
    'battery_runtime' => '.1.3.6.1.2.1.33.1.2.3.0',   # Temps de batterie restant (minutes)
    'battery_charge'  => '.1.3.6.1.2.1.33.1.2.4.0',   # Charge de la batterie (%)

    # Alarmes
    'alarm_count'     => '.1.3.6.1.2.1.33.1.6.1.0',    # Nombre d'alarmes
);

# Variables pour les options de ligne de commande
my ($host, $community, $version, $metric, $help);

# Récupération des paramètres
GetOptions(
    'h=s'  => \$host,
    'c=s'  => \$community,
    'v=s'  => \$version,
    'm=s'  => \$metric,
    'help' => \$help
);

# Affiche l'aide si demandée ou si des paramètres sont manquants
if ($help || !$host || !$community || !$version || !$metric) {
    print_usage();
    exit 3;  # UNKNOWN
}

# Démarrer la session SNMP
my ($session, $error) = Net::SNMP->session(
    -hostname  => $host,
    -community => $community,
    -version   => $version
);

if (!defined($session)) {
    print "CRITICAL - SNMP session error: $error\n";
    exit 2;  # CRITICAL
}

# Si la métrique demandée est "battery", on récupère toutes les infos sur la batterie
if ($metric eq 'battery') {
    my @battery_oids = (
        $oids{'battery_status'},
        $oids{'battery_runtime'},
        $oids{'battery_charge'},
    );

    my $result = $session->get_request(-varbindlist => \@battery_oids);
    
    # Vérifier si l'on a reçu une réponse correcte
    if (!defined($result)) {
        print "CRITICAL - Failed to retrieve battery OIDs: $error\n";
        exit 2;
    }

    # Afficher toutes les informations sur la batterie
    my $status = interpret_battery_status($result->{$oids{'battery_status'}});
    my $runtime = $result->{$oids{'battery_runtime'}};
    my $charge = $result->{$oids{'battery_charge'}};

    print "État de la batterie : $status\n";
    print "Temps restant de la batterie : $runtime minutes\n";
    print "Charge de la batterie : $charge%\n";

    # Déterminer le code de sortie basé sur les métriques
    if ($status =~ /faible|défectueuse/i || $charge < 20) {
        exit 2;  # CRITICAL
    } elsif ($charge < 50) {
        exit 1;  # WARNING
    } else {
        exit 0;  # OK
    }
}

# Si la métrique demandée est "alarm", on récupère les infos sur les alarmes
elsif ($metric eq 'alarm') {
    my @alarm_oids = (
        $oids{'alarm_count'},
    );

    my $result = $session->get_request(-varbindlist => \@alarm_oids);
    
    # Vérifier si l'on a reçu une réponse correcte
    if (!defined($result)) {
        print "CRITICAL - Failed to retrieve alarm OIDs: $error\n";
        exit 2;
    }

    my $alarm_count = $result->{$oids{'alarm_count'}};

    if ($alarm_count == 0) {
        print "OK - Pas d'alarmes présentes\n";
        exit 0;  # OK
    } else {
        print "CRITICAL - Nombre d'alarmes : $alarm_count";
        exit 2;  # CRITICAL
    }
}

# Fermer la session SNMP
$session->close();

# Fonction pour interpréter l'état de la batterie
sub interpret_battery_status {
    my ($status) = @_;
    if ($status == 1) {
        return "Batterie en bonne santé";
    } elsif ($status == 2) {
        return "Batterie faible";
    } elsif ($status == 3) {
        return "Batterie défectueuse";
    } else {
        return "État inconnu";
    }
}

# Fonction pour afficher l'aide
sub print_usage {
    print << "EOF";
Usage: ./eaton.pl -h <host> -c <community> -v <version> -m <metric>

Options:
    -h    Adresse IP de l'onduleur (par exemple : 192.168.1.10)
    -c    Communauté SNMP (par exemple : public)
    -v    Version SNMP (1, 2c ou 3)
    -m    Métrique à interroger (battery, alarm)

Description des métriques :
    battery : Récupère et affiche toutes les informations sur la batterie (statut, charge, tension, courant, temps restant)
    alarm   : Récupère et affiche les informations sur les alarmes (nombre d'alarmes et description)
EOF
}

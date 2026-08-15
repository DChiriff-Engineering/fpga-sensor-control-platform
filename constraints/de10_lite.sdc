# DE10-Lite onboard 50 MHz oscillator.
create_clock -name CLOCK_50 -period 20.000 [get_ports {CLOCK_50}]

# Ask TimeQuest to account for default clock uncertainty on the constrained clock.
derive_clock_uncertainty

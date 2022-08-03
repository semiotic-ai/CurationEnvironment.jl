# ---
# title: Welfare Maximisation in the Community Signal Model
# id: cs_wm
# date: 2022-08-03
# author: "[Anirudh Patel](https://github.com/anirudh2)"
# julia: 1.7
# description: This experiment investigates whether the Community Signal model is welfare-maximising.
# ---


# Welfare maximisation is defined as in the
# [Curation v2](https://www.overleaf.com/read/hfymjbjmzwvf) yellowpaper.
# The main idea is that a welfare-maximising state is one in which curators that value
# subgraph most own the shares and the minimum viable signal is met for all curators
# Generally speaking, as we shall see, there exist equilibria for the Community Signal (CS)
# model of curation that are not welfare-maximising.

using CurationEnvironment

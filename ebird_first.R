if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("ebird/ebird-best-practices")

library(auk)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(lubridate)
library(readr)
library(sf)

f_sed <- "ebd_US-VA-121_smp_relAug-2025_sampling.txt"
checklists <- read_sampling(f_sed)
glimpse(checklists)

checklists[checklists$all_species_reported == TRUE, ]

f_ebd <- "ebd_US-VA-121_smp_relAug-2025.txt"
observations <- read_ebd(f_ebd)
glimpse(observations)

# filter the checklist data
checklists <- checklists |> 
  filter(all_species_reported)

# store the cheklists data here
checklists <- checklists |> 
  filter(all_species_reported,
         between(year(observation_date), 2014, 2026))
write_csv(checklists, "checklists-zf_all_year_montogmery.csv", na = "")

# Checklists with only the data we need
checklists <- checklists |> 
  select(checklist_id, observation_date)
write_csv(checklists, "checklists-id_date.csv", na = "")



# filter the observation data
observations <- observations |> 
  filter(all_species_reported)


# remove observations without matching checklists
observations <- semi_join(observations, checklists, by = "checklist_id")


# Zero filling using sampling data
zf <- auk_zerofill(observations, checklists, collapse = TRUE)
glimpse(zf)

zf <- zf |> 
  mutate(
    # convert count to integer and X to NA
    # ignore the warning "NAs introduced by coercion"
    observation_count = as.integer(observation_count),
    # effort_distance_km to 0 for stationary counts
    effort_distance_km = if_else(protocol_name == "Stationary", 
                                 0, effort_distance_km),
    # convert duration to hours
    effort_hours = duration_minutes / 60,
    # speed km/h
    effort_speed_kmph = effort_distance_km / effort_hours,
    # split date into year and day of year
    year = year(observation_date),
    day_of_year = yday(observation_date)
  )

# additional filtering
zf_filtered <- zf |> 
  filter(protocol_name %in% c("Stationary", "Traveling"),
         effort_hours <= 6,
         effort_distance_km <= 10,
         effort_speed_kmph <= 100,
         number_observers <= 10)


checklists <- zf_filtered |> 
  select(checklist_id, observer_id,
         observation_count, species_observed, 
         state_code, locality_id, latitude, longitude,
         protocol_name, all_species_reported,
         observation_date, year, day_of_year,
         effort_hours, effort_distance_km, effort_speed_kmph,
         number_observers)
write_csv(checklists, "checklists-zf_all_year_montogmery.csv", na = "")



# YEARLY HISTOGRAM
breaks <- seq(as.Date("2010-1-1"), as.Date("2026-1-1"), "years")
labels <- breaks[-length(breaks)] + diff(breaks) / 2

checklists_date <- checklists |> 
  mutate(date_bins = cut(observation_date, 
                         breaks = breaks, 
                         labels = labels,
                         include.lowest = TRUE),
         date_bins = date_bins) |> 
  group_by(date_bins) |> 
    summarise(n_checklists = n(),
            n_detected = sum(species_observed),
             det_freq = mean(species_observed))

# histogram
g_tod_hist <- ggplot(checklists_date) +
  aes(x = date_bins, y = n_checklists) +
  geom_segment(aes(xend = date_bins, y = 0, yend = n_checklists),
               color = "grey50") +
  geom_point() +
  scale_y_continuous(labels = scales::comma) +
  labs(x = "Date",
       y = "# checklists",
       title = "Distribution of observation dates")

# frequency of detection
g_tod_freq <- ggplot(checklists_date |> filter(n_checklists > 100)) +
  aes(x = date_bins, y = det_freq) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Date",
       y = "% checklists with detections",
       title = "Detection frequency")

# combine
grid.arrange(g_tod_hist, g_tod_freq)

# Filtered checklists with main data - this does not work, since we have put zf into checklists
# checklists <- zf_filtered |> 
#   select(checklist_id, observer_id,
#          observation_count, species_observed, 
#          state_code, locality_id, latitude, longitude,
#          protocol_name, all_species_reported,
#          observation_date, year, day_of_year,
#          effort_hours, effort_distance_km, effort_speed_kmph,
#          number_observers)


# Filtered Observations
observations <- observations |> filter(between(year(observation_date), 2014, 2026))
write_csv(observations, "observations-full_2014-2016.csv", na = "")

# Observations with only the data we need
observations <- observations |> 
  select(checklist_id, common_name, observation_count, observation_date)
write_csv(observations, "observations-minimal.csv", na = "")

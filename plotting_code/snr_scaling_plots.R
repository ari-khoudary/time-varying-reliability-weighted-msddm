library(tidyverse)
library(patchwork)


edwards <- function(prior, noise, signal) {
  x0 = (noise^2 / (2 * signal)) * log(prior / (1-prior))
}

link <- function(prior, noise, signal) {
  x0 = (noise^2 / (4 * signal)) * log(prior / (1-prior))
}

noise <- seq(0.1, 2, 0.25)
signal <- seq(0.1, 2, 0.25)
prior <- seq(0.5, 0.99, 0.1)
xmin <- 0

expand_grid(noise = noise, signal = signal, prior) %>%
  mutate(edwards_x0 = edwards(prior, noise, signal),
         link_x0 = link(prior, noise, signal),
         SNR = signal / (noise^2)) %>% 
  filter(SNR > xmin & SNR < 2.1) %>%
  pivot_longer(cols = c(edwards_x0, link_x0), names_to = 'model', values_to = 'x0') %>%
  mutate(model = str_remove(model, '_x0')) %>%
  ggplot(aes(x=SNR, y=x0, color=prior, group=prior)) + 
  facet_wrap(~ model) +
  geom_point(size=1) +
  geom_line() +
  theme_bw() +
  xlim(xmin, 2) +
  labs(x = 'signal-to-noise ratio (A / c^2)', color= expression(paste(Pi))) +
  theme(text = element_text(size=16)) 

ggsave('snr_scaling.png', width=8, height=4, dpi='retina')

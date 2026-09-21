library(tidyverse)
library(patchwork)
library(lme4)
library(lmerTest)
library(emmeans)
library(performance)
library(latex2exp)
library(gtsummary)

options(contrasts = c("contr.sum", "contr.poly"))

# plotting variables
fontSize = 14
diazColor = '#B25A39'
bornsteinColor = '#FBB990'
outdir <- '../figures/seqEffects_singleFigs/'

#### main text figures ####
## determine bornstein cue levels
learnData <- read.csv('../data/seqEffects/data_bornstein_e2.csv') %>% filter(Phase ==1)
cueLevels <- learnData %>%
  group_by(subID, Block, Cue) %>%
  summarise(cueLevel = round(mean(Cue == Image), 1))

#### bornstein regression & plots ####
e2 <- read.csv('../data/seqEffects/data_bornstein_e2.csv') %>% 
  filter(Phase == 2, is.na(RT_from_CueOnset)==0) %>%
  left_join(., cueLevels, by=c('subID', 'Cue', 'Block')) %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT_from_CueOnset)),
         validity = case_when(Cue==Image ~ 'valid', 
                              Cue!=Image ~ 'invalid'),
         prev_response = factor(ifelse(lag(Accuracy)==1, 'correct', 'error')),
         prev_cue = factor(ifelse(lag(cueLevel)==cueLevel, 'same', 'different')),
         prev_target = factor(ifelse(lag(CorrResp)==CorrResp, 'same', 'different')),
         target_category = factor(ifelse(Cue < 3, 'cat1', 'cat2')),
         prev_category = factor(ifelse(lag(target_category)==target_category, 'same', 'different')),
         prev_cueCat = interaction(prev_cue, prev_category, drop = FALSE),
         prev_cueCat = factor(prev_cueCat, 
                              levels=c('different.different', 'different.same', 'same.same'),
                              labels=c('diffCue.diffCat', 'diffCue.sameCat', 'sameCue')),
         CueFac = as.factor(Cue),
         Cue = paste('Cue ', Cue),
         congCue = case_when(cueLevel == 0.5 ~ cueLevel,
                             validity == 'valid' ~ cueLevel,
                             validity == 'invalid' ~ 1-cueLevel),
         Accuracy = ifelse(Accuracy==0, 'incorrect', 'correct'),
         logTrial = log(Trial),
         across(c(Cue, Image, Resp, Accuracy, prev_target, prev_cue, prev_response, cueLevel), as.factor)) %>%
  ungroup() %>%
  filter(is.na(prev_cue)==0)

# fit model
b_model <- lm(zlogRT ~ cueLevel*validity + 
                Accuracy + target_category + 
                prev_response  + Trial +
                prev_cue + prev_target, e2)


# plot by cueLevel
b_summary <- e2 %>%
  filter(is.na(prev_cue)==0) %>%
  mutate(validity = ifelse(cueLevel==0.5, 'neutral', validity)) %>%
  group_by(subID, cueLevel, prev_cue, validity) %>%
  summarise(rt = mean(zlogRT))


b_plot_df <- emmip(b_model, ~ prev_cue | cueLevel*validity, CIs=T, plotit=F, weights='cells') %>%
  as.data.frame() %>%
  mutate(validity = case_when(cueLevel == 0.5 ~ 'neutral',
                              validity == 'valid'   ~ 'valid',
                              validity == 'invalid' ~ 'invalid'),
         cueLevel = factor(cueLevel),
         validity = factor(validity, levels=c('valid', 'invalid', 'neutral'))) %>%
  group_by(prev_cue, cueLevel, validity) %>%
  summarise(yvar = mean(yvar),
            LCL = mean(LCL),
            UCL = mean(UCL))

b_shapes <- c(19, 15, 17, 8)

b_summary %>%
  mutate(cueLevel = factor(cueLevel),
         validity = factor(validity, levels=c('valid', 'invalid', 'neutral'))) %>%
  ggplot(aes(x=prev_cue, y=rt, shape=cueLevel)) + theme_classic() +
  geom_hline(yintercept = 0, linetype='dotted') +
  facet_grid(~validity) +
  scale_shape_manual(values = b_shapes) +
  geom_line(aes(group=interaction(cueLevel, subID)), alpha=0.15, size=0.3, color=bornsteinColor) +
  geom_pointrange(aes(y=yvar, ymin=LCL, ymax=UCL), data=b_plot_df, size=0.7, linewidth=1, color=bornsteinColor,
                  position=position_dodge(width=0.2)) +
  geom_line(aes(y=yvar, group=cueLevel), data=b_plot_df, size=1,color=bornsteinColor, 
            position=position_dodge(width=0.2)) +
  labs(y = 'zlogRT', title = 'learned: Bornstein et al. (2023)', x = 'previous cue') +
  theme(text = element_text(size=fontSize))
ggsave(paste0(outdir, 'b_cue.png'), width=7, height=5, dpi='retina')

# source-related uncertainty
b_model2 <- lm(zlogRT ~ cueLevel*validity + Accuracy + target_category + prev_response + Trial + cueLevel*prev_cue + prev_target, e2)
emmeans(b_model2, ~ cueLevel | prev_cue) %>% contrast('pairwise')

b_model3 <- lm(zlogRT ~ cueLevel*validity + Accuracy + target_category + prev_response + cueLevel*Trial*prev_cue + prev_cue + prev_target, e2)
emmeans(b_model3, ~ Trial | cueLevel & prev_cue, at=list(Trial=c(122, 180))) %>% contrast('pairwise')

#### diaz regression & plots ####
## cueIdx==0 is the 50F cue
## cueIdx==1 is the 30F cue
## cueIdx==2 is the 70F cue
diaz <- read.csv('../data/seqEffects/data_diaz.csv') %>%
  group_by(subID) %>%
  mutate(zlogRT = scale(log(RT)),
         prev_response = factor(ifelse(lag(accuracy)==1, 'correct', 'error')),
         prev_cue = factor(ifelse(lag(cueIdx)==cueIdx, 'same', 'different')),
         prev_target = factor(ifelse(lag(faceCorrect)==faceCorrect, 'same', 'different')),
         cohLevel = factor(ifelse(coh1==1, 'low', 'high')),
         choice = factor(ifelse(faceChoice==1, 'face', 'car')),
         image = factor(ifelse(faceCorrect==1, 'face', 'car')),
         accuracy = ifelse(accuracy==1, 'correct', 'incorrect'),
         cueLevel = case_when(cueIdx==0 ~ 0.5,
                              cueIdx==1 ~ 0.3,
                              cueIdx==2 ~ 0.7),
         cueIdx = paste('Cue ', cueIdx+1),
         validity = case_when(cueLevel < 0.5 ~ 'invalid',
                              cueLevel == 0.5 ~ 'neutral',
                              cueLevel > 0.5 ~ 'valid'),
         validity = factor(validity, levels=c('valid', 'invalid', 'neutral')),
         prev_coh = ifelse(lag(coh1)==coh1, 'same', 'diff'),
         trial = row_number(),
         logTrial = log(trial),
         across(c(prev_cue, image, choice, accuracy, prev_target, prev_response, cueIdx, cueLevel), as.factor)) %>%
  ungroup() %>%
  filter(is.na(prev_cue)==0)

# diaz regression
d_model <- lm(zlogRT ~ validity + 
                accuracy + cohLevel + 
                prev_response + trial + 
                prev_cue + prev_target, diaz) 

# summary data
d_summary <- diaz %>%
  group_by(subID, validity, prev_cue) %>%
  summarise(rt = mean(zlogRT))

d_plot_df <- emmip(d_model, ~ prev_cue | validity, CIs=T, plotit=F, weights = "cells") %>% 
  as.data.frame() 

d_summary %>%
  ggplot(aes(x=prev_cue, y=rt)) + theme_classic() + 
  geom_hline(yintercept = 0, linetype='dotted') +
  facet_grid(~validity) +
  geom_line(aes(group=subID), alpha=0.15, size=0.3, color=diazColor) +
  geom_pointrange(aes(y=yvar, ymin=LCL, ymax=UCL), data=d_plot_df, color=diazColor, size=0.7, linewidth=1) +
  geom_line(aes(y=yvar, group=tvar), data=d_plot_df, color=diazColor, size=1) +
  labs(y = 'zlogRT', title = 'instructed: Diaz, Pisauro et al. (2024)', x = 'previous cue') +
  theme(text = element_text(size=fontSize)) +
  ylim(-0.4, 0.4)
ggsave(paste0(outdir, 'd_cue.png'), width=6.5, height=5, dpi='retina')

emmeans(d_model, ~ prev_cue | validity) %>% contrast('pairwise')
  

#### supplement figures ####
# bornstein: plot target effect
b_plot_target <- emmip(b_model, ~ prev_target | cueLevel*validity, CIs=T, plotit=F) %>% 
  as.data.frame() %>%
  mutate(validity = case_when(cueLevel == 0.5 ~ 'neutral',
                              validity == 'valid'   ~ 'valid',
                              validity == 'invalid' ~ 'invalid'),
         cueLevel = factor(cueLevel),
         validity = factor(validity, levels=c('valid', 'invalid', 'neutral'))) %>%
  group_by(prev_target, cueLevel, validity) %>%
  summarise(yvar = mean(yvar),
            LCL = mean(LCL),
            UCL = mean(UCL))

e2 %>%
  filter(is.na(prev_target)==0) %>%
  mutate(validity = ifelse(cueLevel==0.5, 'neutral', validity),
         validity = factor(validity, levels=c('valid', 'invalid', 'neutral'))) %>%
  group_by(subID, cueLevel, prev_target, validity) %>%
  summarise(rt = mean(zlogRT)) %>%
  ungroup() %>%
  ggplot(aes(x=prev_target, y=rt, shape=cueLevel)) + theme_classic() + 
  geom_hline(yintercept = 0, linetype='dotted') +
  facet_grid(~validity) +
  geom_line(aes(group=interaction(cueLevel, subID)), alpha=0.15, size=0.3, color='gray50') +
  geom_line(aes(y=yvar, group=cueLevel), data=b_plot_target, size=1, color='gray50',
            position=position_dodge(width=0.1)) +
  scale_shape_manual(values = b_shapes) +
  geom_pointrange(aes(y=yvar, ymin=LCL, ymax=UCL), data=b_plot_target, size=0.7, linewidth=1, 
                  position=position_dodge(width=0.2), color='gray50') +
  labs(y = 'zlogRT', title = 'learned: Bornstein et al. (2023)', x = 'previous target') +
  theme(text = element_text(size=fontSize))
ggsave(paste0(outdir, 'b_target.png'), width=7, height=5, dpi='retina')

# diaz: plot target
d_plot_target <- emmip(d_model, ~ prev_target | validity, CIs=T, plotit=F, weights = "cells") %>% 
  as.data.frame() 

diaz %>%
  group_by(subID, validity, prev_target) %>%
  filter(is.na(prev_target)==0) %>%
  summarise(rt = mean(zlogRT)) %>%
  ggplot(aes(x=prev_target, y=rt)) + theme_classic() + 
  geom_hline(yintercept = 0, linetype='dotted') +
  #facet_grid(~cueLevel, labeller = as_labeller(cue_labels, default = label_parsed)) +
  facet_grid(~validity) +
  #geom_point(position=position_jitter(width=0.15, height=0), alpha=0.25, color='gray50') +
  geom_line(aes(group=subID), alpha=0.15, size=0.3, color='gray50') +
  geom_pointrange(aes(y=yvar, ymin=LCL, ymax=UCL), data=d_plot_target, color='gray50', size=0.7, linewidth=1) +
  geom_line(aes(y=yvar, group=tvar), data=d_plot_target, color='gray50', size=1) +
  labs(y = 'zlogRT', title = 'instructed: Diaz, Pisauro et al. (2024)', x = 'previous target') +
  ylim(-0.4, 0.4) +
  theme(text = element_text(size=fontSize))
ggsave(paste0(outdir, 'd_target.png'), width=6.5, height=5, dpi='retina')

## regression summary tables
b_model %>%
  tbl_regression() %>%
  modify_header(statistic = '**t-statistic**',
                std.error = '**SE**') %>%
  add_glance_source_note(include = c(nobs, sigma, statistic, p.value, df, df.residual)) %>%
  as_gt() %>%
  gt::gtsave('../figures/summary_b.tex')

d_model %>%
  tbl_regression() %>%
  modify_header(statistic = '**t-statistic**',
                std.error = '**SE**') %>%
  add_glance_source_note(include = c(nobs, sigma, statistic, p.value, df, df.residual)) %>%
  as_gt() %>%
  gt::gtsave('../figures/summary_d.tex')

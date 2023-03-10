##### VAE model for lcpm context
##### Layer width: 20K | 512 | 256 |--64--| 256 | 512 | 20K

# Model parameters 
neck <- 64L # Latent dimension 
drop_rate <- 0.1 #
gene_dim <- ngenes  #Number of features (genes) in the dataset
latent_dim <- neck
epsilon_std <- 0.5  ##Standard deviation of the prior latent distribution (vanilla =1)
var_prior <- epsilon_std**2
log_var_prior <- log(var_prior)
kl_weight <- 0.2   #Weight for the Kulllback-Leibler divergence loss (vanilla =1 )

# Encoder definition:
x <- keras::layer_input(shape = c(gene_dim), name="gene_input")
h <- keras::layer_dense(x, 8 * neck, activation = "elu")
h <- keras::layer_dropout(h, rate = drop_rate)
h <- keras::layer_dense(h, 4 * neck, activation = "elu")
h <- keras::layer_dropout(h, rate = drop_rate)

z_mean <- keras::layer_dense(h, latent_dim)
z_log_var <- keras::layer_dense(h, latent_dim)

#### Sampling from the latent space:
sampling <- function(arg) {
    z_mean <- arg[, seq_len(latent_dim)]
    z_log_var <- arg[, (latent_dim + 1):(2 * latent_dim)]
    epsilon <- K$random_normal(
        shape = c(K$shape(z_mean)[[1]]),
        mean = 0.,
        stddev = epsilon_std
    )
    z_mean + K$exp(z_log_var/2)*epsilon
}

# Lambda layer for variational sampling:
z <- keras::layer_concatenate(list(z_mean, z_log_var)) %>%
    keras::layer_lambda(sampling)

# instantiate decoder:
decoder_h <- keras::keras_model_sequential()
decoder_h %>%
    keras::layer_dense(units = 4 * neck, activation = "elu") %>%
    keras::layer_dropout(rate = drop_rate) %>%
    keras::layer_dense(8 * neck, activation = "elu") %>%
    keras::layer_dropout(rate = drop_rate)

decoder_mean <- keras::layer_dense(units = gene_dim, activation = "relu")
h_decoded <- decoder_h(z)
x_decoded_mean <- decoder_mean(h_decoded)

# end-to-end autoencoder:
vae <- keras::keras_model(x, x_decoded_mean)

# encoder:
encoder <- keras::keras_model(x, z_mean)

# generator, from latent space to reconstructed inputs
decoder_input <- keras::layer_input(shape = latent_dim)
h_decoded_2 <- decoder_h(decoder_input)
x_decoded_mean_2 <- decoder_mean(h_decoded_2)
generator <- keras::keras_model(decoder_input, x_decoded_mean_2)










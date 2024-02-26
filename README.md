Fetches ice charts from https://ocean.dmi.dk/arctic/icecharts_gl_capefarewell.uk.php and provides a couple of basic UIs making chart comparison easier.

The root page shows two charts of any date side by side: https://dk-ice-charts-compare.gregdev.com

The /previous page shows the selected date's chart and then all charts from the previous 60 days: https://dk-ice-charts-compare.gregdev.com/previous

Deploy:

```
git push dokku main
```

Having previously added the remote:

```
git remote add origin git@github.com:grega/dk-ice-charts-compare.git
```

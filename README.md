# autoshutdown script for Qubes OS

## Important warnings
**Disclaimer:** This script is not maintained by the Qubes OS team.

**Warning:** This script is rather experimental. You might find it useful, but it might also cease to work, shut down a VM you are using and so on.

## Installation

You need xdotool installed in dom0.

Copy auto-shutdown.desktop to ~/.config/autostart and fix the path in the file. After this operation, the script will start on every login.

**Don't install it in crontab**, since it has no access to the `$DISPLAY`. In a previous version, this caused sudden VM shutdowns, sorry for that. The current version is more fail-safe and it just considers all VMs as active when xdotool fails for such reason. This is still not what we want, but it at least does not any harm in such situation.

## Modularity

The script is modular: You can add a new strategy for determining if a VM is *active*. If a VM is *active*, it is doing something potentially useful. If VM is not active, it might be running, but without being useful. There are currently two strategies:

* Blacklist: always marks `dom0`, `sys-net` and `sys-firewall` as *active*.
* X11: marks all VMs with a visible window (it seemingly includes systray icons) as *active*.

## Known issues

### Potential race condition

When VM is about being shut down and user starts an app, it might not notice the user's action in time. This might be improved by tight cooperation with Dom0<->DomU communication libraries.

With a following assumption and a tight cooperation, we could even fully fix the race condition: When a VM is not *active*, it will not begin *active* unless user does some action through Qubes RPC.

* This assumption seems to be reasonable. User can't directly interact with machines without a visible X11 window. He might interact through Qubes RPC or (in some special cases) through other interfaces like network and peripherial devices.
	* When user interacts through network or some periprerial device, he should blacklist the VM from automatic shutdown.
	* When the user interacts through Qubes RPC, we can catch it by some tight integration.
* If Qubes core agent provides shutdownPrepare and shutdownProceed functions, we could fully fix the race condition.
	* The shutdownPrepare function would change the API state to *preparing-for-shutdown* and return a new ShutdownTicket. The VM is in *preparing-for-shutdown* state iff there is a valid ShutdownTicket.
	* Any Qubes RPC call (except some special cases) would invalidate the ShutdownTicket. (It would invalidate all ShutdownTicket-s if we allow more valid ShutdownTicket-s at one time instant. But I don't find multiple ShutdownTickets useful.)
	* After shutdownPrepare call, the script can check if a VM is active. If so, the ShutdownTicket shall be cancelled.
	* When all *activity*-related checks are passed and the VM is found to be *inactive*, the shutdownProceed function with the corresponding ShutdownTicket is called.
	* The shutdownProceed function shuts the machine down iff the ShutdownTicket is valid.
	* Some serialization in Qubes RPC calls is assumed. I am not sure about the RPC design, but I hope this assumption is reasonable. If there is no serialization, we would have to create it using a R/W lock.

### It does not react to amount of free RAM

It does the shutdown even if there is much free RAM. It could be optimized to shut the VM down iff there is low memory. This would however need either a frequent polling (=> higher CPU and power consumption) or tight cooperation with the Qubes memory manager.

### Service VMs

If you are using a service VM, it should be blacklisted. See `activity.d/00_blacklist`. The sys-firewall, sys-net and dom0 VMs are balcklisted by default. If you create a TorVM, USBVM, StorageVM or a ServerVM, you might want to add it to the blacklist.

### Some edge cases

Yes, some parts of the script are hacky, especially the function qvm-ls-running. When searching for windows of a particular name, I pass the name as regexp, is also not ideal. These parts might fail in some special conditions.

### Paused VMs

Paused VMs were not considered in the development. There is however probably no reason why they can't be supported. The X11 check should be possible on paused VMs, too. The blacklist is even simpler. But some custom checks might require some qvm-run call and so on.

When this script seems to work well on running VMs, paused VMs might be considered.

## Will it be adopted by Qubes OS?

This script is now rather a proof of concept and it will unlikely be added to Qubes without any modification. If you are interested about implementing this feature to Qubes, look at the related issue: https://github.com/QubesOS/qubes-issues/issues/832

## License

WTFPL, without any warranty.

import matplotlib.pyplot as plt
import matplotlib.cm as cm
import numpy as np

def normalize(numbers: list[float], val: float) -> list[float]:
    return [round(num / (sum(numbers)/val), 4) for num in numbers]

nums = [1.0]
for i in range(0, 12):
    nums = normalize(nums, val=0.75)
    nums.append(0.25)
    print(i, nums)

if True:
    nums = [round(((1/12)/num), 4) for num in nums]

print("Final:", nums)
# --- Graph ---
colors = cm.viridis(np.linspace(0.2, 0.9, len(nums)))
fig, ax = plt.subplots(figsize=(8, 5))
bars = ax.bar(range(len(nums)), nums, color=colors, edgecolor="white", linewidth=0.5)
for bar, val in zip(bars, nums):
    ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.002,
            str(val), ha="center", va="bottom", fontsize=8)
ax.set_title("Final Distribution (Iteration 11)")
ax.set_xlabel("Slot index")
ax.set_ylabel("Value")
ax.set_xticks(range(len(nums)))
plt.tight_layout()
plt.show()
